#!/usr/bin/env bash
#
# Tests for script/ssh-config-sync. Drives the script against a fake `op` so
# the fetch/validate/write/prune logic runs without touching 1Password or the
# real ~/.ssh.
#
# Run: script/tests/ssh-config-sync.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../ssh-config-sync

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fx=$work/fixtures

cat >"$work/op" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$FIXTURES/calls"
[ -f "$FIXTURES/stderr-noise" ] && echo 'A new version of 1Password CLI is available' >&2
if [ "${1:-}" = --account ]; then shift 2; fi
case "${1:-}" in
  whoami)
    # Models reality: whoami succeeds even when signed out.
    echo 'URL: https://example.1password.com'
    exit 0
    ;;
  vault)
    [ -f "$FIXTURES/auth-hang" ] && exec sleep 3017
    if [ -f "$FIXTURES/auth-fail" ]; then
      echo '[ERROR] You are not currently signed in' >&2
      exit 1
    fi
    echo '{"id":"v1","name":"Private"}'
    exit 0
    ;;
  item)
    case "${2:-}" in
      list)
        if [ -f "$FIXTURES/auth-fail" ]; then
          echo '[ERROR] You are not currently signed in' >&2
          exit 1
        fi
        [ -f "$FIXTURES/list-fail" ] && exit 1
        cat "$FIXTURES/list.json"
        exit 0
        ;;
      get)
        if [ -f "$FIXTURES/auth-fail" ]; then
          echo '[ERROR] You are not currently signed in' >&2
          exit 1
        fi
        [ -f "$FIXTURES/get-fail-$3" ] && exit 1
        cat "$FIXTURES/items/$3.json"
        exit 0
        ;;
    esac
    ;;
esac
echo "unexpected: $*" >&2
exit 1
FAKE
chmod +x "$work/op"

failures=0
check() {
  local label=$1 expected=$2 actual=$3
  if [ "$expected" = "$actual" ]; then
    printf '  ok   %s\n' "$label"
  else
    printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$label" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

mode_of() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }

reset() {
  rm -rf "${fx:?}" "${work:?}/home"
  mkdir -p "$fx/items" "$work/home/.ssh"
  echo '[]' >"$fx/list.json"
}

add_item() {
  local id=$1 title=$2 body=$3
  jq -n --arg id "$id" --arg t "$title" --arg b "$body" \
    '{id: $id, title: $t, fields: [{id: "notesPlain", label: "notesPlain", value: $b}]}' >"$fx/items/$id.json"
  jq --arg id "$id" --arg t "$title" '. + [{id: $id, title: $t}]' "$fx/list.json" >"$fx/list.tmp"
  mv "$fx/list.tmp" "$fx/list.json"
}

cfgd=$work/home/.ssh/config.d

# Runs the script with every seam pointed into $work. Extra VAR=value pairs
# can be passed as arguments and are applied via env.
run_sync() {
  rm -f "$fx/calls"
  env -u SSH_CONNECTION FIXTURES="$fx" OP_BIN="$work/op" OP_TIMEOUT=2 \
    SSH_CONFIG_D="$cfgd" WORK_MACHINE_FLAG="$work/no-such-flag" \
    GCW_MARKER="$work/no-such-gcw" UNAME_S=Linux "$@" "$subject" >"$work/out" 2>"$work/err"
}

exit_of() { if run_sync "$@"; then echo 0; else echo nonzero; fi; }
header() { printf '# managed by ssh-config-sync -- edit in 1Password: %s' "$1"; }
ls_cfgd() { [ -d "$cfgd" ] && (cd "$cfgd" && ls -A | tr '\n' ' ' | sed 's/ $//'); return 0; }

echo "ssh-config-sync"

# --- writes each item with the header, 0600 file, 0700 dir -------------------
reset
add_item a1 fractal $'Host fractal-host2\n  HostName 203.0.113.7'
add_item a2 chesal.net $'Host chesal.net\n  User root'
check "happy path exits 0" 0 "$(exit_of)"
check "writes both files" "chesal.net fractal" "$(ls_cfgd)"
check "first line is the header" "$(header fractal)" "$(head -1 "$cfgd/fractal")"
check "body follows the header" "  HostName 203.0.113.7" "$(sed -n 3p "$cfgd/fractal")"
check "file mode 0600" 600 "$(mode_of "$cfgd/fractal")"
check "dir mode 0700" 700 "$(mode_of "$cfgd")"

# --- rerun is idempotent -----------------------------------------------------
before=$(cat "$cfgd/fractal")
run_sync
check "rerun leaves content unchanged" "$before" "$(cat "$cfgd/fractal")"

# --- prunes a managed file whose item is gone, keeps unmanaged files ---------
printf 'Host handmade\n' >"$cfgd/handmade"
reset_keep() { rm -rf "${fx:?}"; mkdir -p "$fx/items"; echo '[]' >"$fx/list.json"; }
reset_keep
add_item a1 fractal $'Host fractal-host2'
run_sync
check "prunes the stale managed file" "fractal handmade" "$(ls_cfgd)"

# --- zero items while managed files exist: warn, prune nothing ---------------
reset_keep
check "zero items exits 0" 0 "$(exit_of)"
check "zero items prunes nothing" "fractal handmade" "$(ls_cfgd)"
check "zero items warns" yes "$(grep -q 'refusing to prune' "$work/err" && echo yes || echo no)"

# --- op printing nothing for an empty list counts as zero items --------------
: >"$fx/list.json"
check "empty list output exits 0" 0 "$(exit_of)"
check "empty list output prunes nothing" "fractal handmade" "$(ls_cfgd)"

# --- never overwrites an unmanaged file with the same name -------------------
reset
printf 'Host mine\n' >"$work/home/.ssh/placeholder"
mkdir -p "$cfgd"
printf 'Host handmade\n' >"$cfgd/handmade"
add_item a1 handmade $'Host from-1password'
add_item a2 other $'Host other'
check "collision exits 0" 0 "$(exit_of)"
check "unmanaged file untouched" "Host handmade" "$(cat "$cfgd/handmade")"
check "collision warns" yes "$(grep -q "not managed by ssh-config-sync" "$work/err" && echo yes || echo no)"
check "other item still written" "$(header other)" "$(head -1 "$cfgd/other")"

# --- bad titles are skipped with a warning -----------------------------------
reset
add_item b1 . 'Host dot'
add_item b2 .. 'Host dotdot'
add_item b3 .hidden 'Host hidden'
add_item b4 'has space' 'Host space'
add_item b5 good 'Host good'
check "bad titles exit 0" 0 "$(exit_of)"
check "only the good title is written" good "$(ls_cfgd)"
check "bad title warns" 4 "$(grep -c 'invalid title' "$work/err")"
check "nothing escaped config.d" "config.d" "$(cd "$work/home/.ssh" && ls -A | tr '\n' ' ' | sed 's/ $//')"

# --- duplicate titles are a fault: nothing written ---------------------------
reset
add_item d1 dup 'Host one'
add_item d2 dup 'Host two'
add_item d3 fine 'Host fine'
check "duplicate titles exit nonzero" nonzero "$(exit_of)"
check "duplicate titles write nothing" "" "$(ls_cfgd)"

# --- titles differing only in case are duplicates too ------------------------
# On macOS's case-insensitive filesystem they would land in the same file, so
# they are refused everywhere and every machine behaves the same.
reset
add_item u1 Fractal 'Host one'
add_item u2 fractal 'Host two'
check "case-only duplicate titles exit nonzero" nonzero "$(exit_of)"
check "case-only duplicate titles write nothing" "" "$(ls_cfgd)"

# --- a title ending in .id cannot clobber another note's staged state --------
reset
add_item x1 x.id 'Host dot-id'
add_item x2 x 'Host plain'
check "x and x.id both sync" 0 "$(exit_of)"
check "x and x.id both written" "x x.id" "$(ls_cfgd)"
check "x keeps its own body" "Host plain" "$(sed -n 2p "$cfgd/x")"
check "x.id keeps its own body" "Host dot-id" "$(sed -n 2p "$cfgd/x.id")"

# --- notes returned but all skipped: say so, prune nothing -------------------
reset
mkdir -p "$cfgd"
printf '%s\nHost old\n' "$(header old)" >"$cfgd/old"
add_item k1 skipped ''
check "all-skipped exits 0" 0 "$(exit_of)"
check "all-skipped prunes nothing" old "$(ls_cfgd)"
check "all-skipped warning names the skips" yes \
  "$(grep -q '1 note(s) but all were skipped' "$work/err" && echo yes || echo no)"
check "all-skipped warning does not claim no notes" no \
  "$(grep -q 'returned no' "$work/err" && echo yes || echo no)"

# --- empty body is skipped with a warning ------------------------------------
reset
add_item e1 empty ''
add_item e2 full 'Host full'
check "empty body exits 0" 0 "$(exit_of)"
check "empty body not written" full "$(ls_cfgd)"
check "empty body warns" yes "$(grep -q 'empty note' "$work/err" && echo yes || echo no)"

# --- CRLF bodies are normalised ------------------------------------------------
reset
add_item c1 crlf $'Host crlf\r\n  User ian\r'
run_sync
check "CR stripped" 0 "$(grep -c $'\r' "$cfgd/crlf" || true)"

# --- stderr noise from a successful op is ignored ------------------------------
reset
touch "$fx/stderr-noise"
add_item n1 noisy 'Host noisy'
check "stderr noise exits 0" 0 "$(exit_of)"
check "stderr noise still writes" "Host noisy" "$(sed -n 2p "$cfgd/noisy")"

# --- fresh machine: no ~/.ssh yet ----------------------------------------------
reset
rm -rf "$work/home/.ssh"
add_item f1 fresh 'Host fresh'
run_sync
check "creates ~/.ssh 0700" 700 "$(mode_of "$work/home/.ssh")"
check "creates config.d 0700" 700 "$(mode_of "$cfgd")"

# --- skips: no op, work machine, gcw, macOS over SSH -----------------------------
reset
add_item s1 skipme 'Host skipme'
check "absent op skips cleanly" 0 "$(exit_of OP_BIN="$work/definitely-not-op")"
check "absent op writes nothing" "" "$(ls_cfgd)"

check "absent jq skips cleanly" 0 "$(exit_of JQ_BIN="$work/definitely-not-jq")"
check "absent jq writes nothing" "" "$(ls_cfgd)"
check "absent jq never calls op" no "$([ -s "$fx/calls" ] && echo yes || echo no)"
check "absent jq notice" yes \
  "$(grep -qF 'Skipping ssh-config-sync -- no jq command found' "$work/err" && echo yes || echo no)"

touch "$work/flag"
check "work machine skips" 0 "$(exit_of WORK_MACHINE_FLAG="$work/flag")"
check "work machine never calls op" no "$([ -s "$fx/calls" ] && echo yes || echo no)"

mkdir -p "$work/gcw"
check "gcw skips" 0 "$(exit_of GCW_MARKER="$work/gcw")"
check "gcw never calls op" no "$([ -s "$fx/calls" ] && echo yes || echo no)"

check "macOS over SSH skips" 0 "$(exit_of UNAME_S=Darwin SSH_CONNECTION='10.0.0.1 1 10.0.0.2 22')"
check "macOS over SSH never calls op" no "$([ -s "$fx/calls" ] && echo yes || echo no)"
check "macOS over SSH notice" yes \
  "$(grep -qF "1Password would prompt on the Mac's display -- skipping over SSH. Run 'just ssh::sync' at the console." "$work/err" && echo yes || echo no)"

# Linux over SSH is fine: op there uses the daemon session, no GUI prompt.
check "Linux over SSH still syncs" 0 "$(exit_of SSH_CONNECTION='10.0.0.1 1 10.0.0.2 22')"
check "Linux over SSH writes" skipme "$(ls_cfgd)"

# --- vault check fails (signed out; whoami still succeeds): exit 0, notice, nothing touched --------------------------------
reset
add_item w1 locked 'Host locked'
touch "$fx/auth-fail"
check "signed-out vault check exits 0" 0 "$(exit_of)"
check "signed-out vault check writes nothing" "" "$(ls_cfgd)"
check "signed-out vault check never reaches item list" no "$(grep -q 'item list' "$fx/calls" && echo yes || echo no)"
check "signed-out vault check notice" yes \
  "$(grep -qF '1Password CLI not signed in -- skipping. Run: eval "$(op signin)" && just ssh::sync' "$work/err" && echo yes || echo no)"

# --- vault check hanging past OP_TIMEOUT: exit 0, nothing touched ---------------------
reset
add_item h1 hung 'Host hung'
touch "$fx/auth-hang"
start=$(date +%s)
check "hung vault check exits 0" 0 "$(exit_of OP_TIMEOUT=1)"
elapsed=$(($(date +%s) - start))
check "hung vault check gives up within the timeout" yes "$([ "$elapsed" -lt 10 ] && echo yes || echo no)"
check "hung vault check writes nothing" "" "$(ls_cfgd)"
# The fake sleeps for a distinctive 3017s; none may be left after the timeout kill.
check "hung vault check leaves no orphaned op" no "$(pgrep -f 'sleep 301[7]' >/dev/null && echo yes || echo no)"
pkill -f 'sleep 301[7]' 2>/dev/null || true

# --- op failure after the preflight: nonzero, nothing changed ---------------------
reset
mkdir -p "$cfgd"
printf '%s\nHost old\n' "$(header old)" >"$cfgd/old"
add_item g1 one 'Host one'
add_item g2 two 'Host two'
touch "$fx/get-fail-g2"
check "get failure exits nonzero" nonzero "$(exit_of)"
check "get failure writes and prunes nothing" old "$(ls_cfgd)"

rm -f "$fx/get-fail-g2"
touch "$fx/list-fail"
check "list failure exits nonzero" nonzero "$(exit_of)"
check "list failure changes nothing" old "$(ls_cfgd)"

# --- OP_ACCOUNT is passed to every op call -----------------------------------------
reset
add_item k1 acct 'Host acct'
run_sync OP_ACCOUNT=chesal
check "every call carries --account" 0 "$(grep -cv '^--account chesal ' "$fx/calls" || true)"
check "account calls happened" yes "$([ -s "$fx/calls" ] && echo yes || echo no)"

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
