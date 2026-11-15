#!/usr/bin/env bash
#
# Tests for home/dot_config/herdr/executable_machines.sh. Drives the script
# against a fake herdr whose saved machines live in a scratch JSON file, so no
# real machine is enabled or disabled.
#
# Run: script/tests/herdr-machines.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/herdr/executable_machines.sh

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

id_a=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
id_b=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

# A fake herdr: `machine list --json` prints $MACHINES_FILE, and
# `machine enable|disable <id>` flips that id's flag in it. Every call is
# recorded one per line.
mkdir -p "$work/bin"
cat >"$work/bin/herdr" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$HERDR_CALLS"
case "$1 $2" in
  'machine list') cat "$MACHINES_FILE" ;;
  'machine enable' | 'machine disable')
    flag=false
    [ "$2" = enable ] && flag=true
    jq --arg id "$3" --argjson f "$flag" 'map(if .id == $id then .enabled = $f else . end)' \
      "$MACHINES_FILE" >"$MACHINES_FILE.new"
    mv "$MACHINES_FILE.new" "$MACHINES_FILE"
    ;;
esac
FAKE
chmod +x "$work/bin/herdr"

reset_machines() {
  cat >"$work/machines.json" <<JSON
[
  {"id":"$id_a","label":"tranquility","target":"tranquility","session":"default","enabled":true,"selected":false},
  {"id":"$id_b","label":"synology01","target":"admin@nas","session":"default","enabled":false,"selected":false}
]
JSON
}

run() {
  : >"$work/calls"
  HERDR_CALLS=$work/calls MACHINES_FILE=$work/machines.json HERDR_BIN=$work/bin/herdr \
    "$subject" "$@" >"$work/out" 2>"$work/err"
}

enabled_of() {
  jq -r --arg id "$1" '.[] | select(.id == $id) | .enabled' "$work/machines.json"
}

echo "herdr-machines"

# --- --list: id first (hidden by fzf), then state, label, target -------------
reset_machines
run --list
check "lists one line per machine" "2" "$(wc -l <"$work/out" | tr -d ' ')"
check "id is the first column" "$id_a $id_b" "$(cut -f1 "$work/out" | tr '\n' ' ' | sed 's/ $//')"
check "shows state, label and target" "enabled|tranquility|tranquility" \
  "$(head -n 1 "$work/out" | cut -f2- | tr -s ' ' | sed 's/ \t/\t/; s/\t/|/g')"
check "shows a disabled machine as disabled" "disabled|synology01|admin@nas" \
  "$(sed -n 2p "$work/out" | cut -f2- | tr -s ' ' | sed 's/ \t/\t/; s/\t/|/g')"

# --- toggle flips each id the right way --------------------------------------
reset_machines
run toggle "$id_a"
check "disables an enabled machine" "false" "$(enabled_of "$id_a")"
check "calls disable with the id" "1" "$(grep -c -- "^machine disable $id_a$" "$work/calls" || true)"
check "leaves the other machine alone" "false" "$(enabled_of "$id_b")"

reset_machines
run toggle "$id_b"
check "enables a disabled machine" "true" "$(enabled_of "$id_b")"

reset_machines
run toggle "$id_a" "$id_b"
check "toggles several: first disabled" "false" "$(enabled_of "$id_a")"
check "toggles several: second enabled" "true" "$(enabled_of "$id_b")"

# --- an unknown id fails without touching anything ---------------------------
reset_machines
if run toggle cccccccccccccccccccccccccccccccc; then
  check "unknown id fails" "nonzero exit" "exit 0"
else
  check "unknown id fails" "nonzero exit" "nonzero exit"
fi
check "unknown id enables/disables nothing" "0" "$(grep -c -E -- '^machine (enable|disable)' "$work/calls" || true)"

# --- a bad argument is a usage error -----------------------------------------
if run --bogus; then
  check "bad argument fails" "nonzero exit" "exit 0"
else
  check "bad argument fails" "nonzero exit" "nonzero exit"
fi

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
