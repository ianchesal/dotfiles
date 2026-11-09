#!/usr/bin/env bash
#
# Tests for home/dot_config/zsh/functions/handoff-sync. Autoloads the function
# in a clean zsh and drives it against a fake mutagen and a fake ssh, so no
# real session is created and nothing is dialled.
#
# Run: script/tests/handoff-sync.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
functions=$here/../../home/dot_config/zsh/functions

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

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

mkdir -p "$work/bin"

# A fake mutagen that records its argv one call per line. `sync list` prints
# $SESSIONS (session names, one per line), defaulting to none.
cat >"$work/bin/mutagen" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$MUTAGEN_CALLS"
if [ "$1 $2" = "sync list" ] && [ -n "${SESSIONS:-}" ]; then
  printf '%s\n' "$SESSIONS"
fi
FAKE
chmod +x "$work/bin/mutagen"

# A fake ssh that fails until it has been called $SSH_UP_AFTER times
# ("never" keeps it down), counting attempts in $SSH_COUNT.
cat >"$work/bin/ssh" <<'FAKE'
#!/usr/bin/env bash
n=$(( $(cat "$SSH_COUNT" 2>/dev/null || echo 0) + 1 ))
echo "$n" >"$SSH_COUNT"
[ "$SSH_UP_AFTER" != never ] && [ "$n" -ge "$SSH_UP_AFTER" ]
FAKE
chmod +x "$work/bin/ssh"

# run [VAR=value ...] -- [handoff-sync args]; sets $rc.
run() {
  local -a env=()
  while [ "$1" != -- ]; do env+=("$1"); shift; done
  shift
  : >"$work/calls"
  rm -f "$work/ssh-count"
  rc=0
  env PATH="$work/bin:$PATH" MUTAGEN_CALLS="$work/calls" SSH_COUNT="$work/ssh-count" SSH_UP_AFTER=1 \
    XDG_STATE_HOME="$work/state" HANDOFF_SYNC_DIR="$work/handoff" HANDOFF_SYNC_INTERVAL=0 \
    "${env[@]}" \
    zsh -f -c 'fpath=("$1" $fpath); autoload -Uz handoff-sync; shift; handoff-sync "$@"' zsh "$functions" "$@" \
    >"$work/out" 2>"$work/err" || rc=$?
}
calls() { cat "$work/calls"; }
ssh_count() { cat "$work/ssh-count" 2>/dev/null || echo 0; }

echo "handoff-sync"

run SESSIONS=handoff --
check "existing session: exits 0" 0 "$rc"
check "existing session: resumes it, never creates" \
  "daemon start|sync list --label-selector dotfiles=handoff --template {{range .}}{{.Name}}{{\"\\n\"}}{{end}}|sync resume --label-selector dotfiles=handoff" \
  "$(calls | paste -sd'|' -)"
check "existing session: never dials ssh" 0 "$(ssh_count)"

run --
check "reachable: exits 0" 0 "$rc"
check "reachable: creates the session" \
  "sync create --name handoff --label dotfiles=handoff --mode two-way-safe --ignore-vcs --ignore .DS_Store $work/handoff gcw:~/src/handoff" \
  "$(calls | tail -n 1)"
check "reachable: makes the local dir 0700" 700 "$(stat -c %a "$work/handoff" 2>/dev/null || stat -f %Lp "$work/handoff")"

run HANDOFF_SYNC_HOST=elsewhere --
check "host override reaches the beta URL" "elsewhere:~/src/handoff" "$(calls | tail -n 1 | awk '{print $NF}')"

run SSH_UP_AFTER=never --
check "unreachable without --wait: exits 1" 1 "$rc"
check "unreachable without --wait: tries ssh once" 1 "$(ssh_count)"
check "unreachable without --wait: no create" "" "$(calls | grep 'sync create' || true)"
check "unreachable without --wait: says why" yes "$(grep -q 'not reachable' "$work/err" && echo yes || echo no)"

run SSH_UP_AFTER=3 -- --wait
check "--wait: exits 0 once the host answers" 0 "$rc"
check "--wait: polled until up" 3 "$(ssh_count)"
check "--wait: then creates" yes "$(calls | grep -q '^sync create' && echo yes || echo no)"

run SSH_UP_AFTER=never HANDOFF_SYNC_TIMEOUT=0 -- --wait
check "--wait timeout: exits 1" 1 "$rc"
check "--wait timeout: no create" "" "$(calls | grep 'sync create' || true)"
check "--wait timeout: says so" yes "$(grep -q 'gave up' "$work/err" && echo yes || echo no)"

run -- --bogus
check "bad argument: exits 2" 2 "$rc"
check "bad argument: no mutagen calls" "" "$(calls)"

run MUTAGEN_BIN="$work/no-such-mutagen" --
check "no mutagen: exits 1" 1 "$rc"

# A held lock means another handoff-sync is already waiting: step aside quietly.
mkdir -p "$work/state"
: >"$work/state/handoff-sync.lock"
zsh -f -c 'zmodload zsh/system; zsystem flock -f fd "$1"; sleep 5' zsh "$work/state/handoff-sync.lock" &
holder=$!
sleep 0.5
run --
kill "$holder" 2>/dev/null || true
wait "$holder" 2>/dev/null || true
check "lock held: exits 0" 0 "$rc"
check "lock held: no mutagen calls" "" "$(calls)"

if [ "$failures" -gt 0 ]; then
  echo "handoff-sync: $failures failure(s)"
  exit 1
fi
