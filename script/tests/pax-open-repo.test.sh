#!/usr/bin/env bash
#
# Tests for home/dot_config/tmux/workmux/executable_pax-open-repo.sh. Drives the
# script against a fake tmux and a scratch ~/src so no real session is created.
#
# Run: script/tests/pax-open-repo.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/tmux/workmux/executable_pax-open-repo.sh

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

# A fake tmux that records its argv one call per line and reports "no session".
# new-session and split-window print an id because the script captures them
# with -P -F: real tmux indices start at 1 here (base-index), so the script must
# never compute ":0" and the fake must not let it get away with doing so.
cat >"$work/tmux" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$TMUX_CALLS"
case "${1:-}" in
  has-session) exit 1 ;;
  new-session) echo '@9' ;;
  split-window) echo '%7' ;;
esac
exit 0
FAKE
chmod +x "$work/tmux"

# A fake tmux that reports the session already exists.
cat >"$work/tmux-existing" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$TMUX_CALLS"
case "${1:-}" in
  new-session) echo '@9' ;;
  split-window) echo '%7' ;;
esac
exit 0
FAKE
chmod +x "$work/tmux-existing"

src=$work/src
mkdir -p "$src/toplevel/.git" "$src/org/nested/.git" "$src/org/nested__worktrees/wt/.git" \
  "$src/persona-web/.git"

run() {
  : >"$work/calls"
  TMUX_CALLS=$work/calls SRC_ROOT=$src TMUX_BIN=${1:-$work/tmux} \
    PORT_REGISTRY=$work/ports PAX_BIN=paxfake \
    "$subject" "${@:2}" >"$work/out" 2>"$work/err"
}

echo "pax-open-repo"

# --- enumeration finds both depths and excludes worktree storage -------------
PAX_LIST_ONLY=1 SRC_ROOT=$src PORT_REGISTRY=$work/ports "$subject" >"$work/list" 2>&1
check "lists both repo depths" "nested persona-web toplevel" "$(awk '{print $1}' "$work/list" | sort | tr '\n' ' ' | sed 's/ $//')"
check "excludes __worktrees" "0" "$(grep -c '__worktrees' "$work/list" || true)"

# --- port allocation is stable and collision-free ----------------------------
rm -f "$work/ports"
run "$work/tmux" toplevel
first=$(awk '$1 == "toplevel" { print $2 }' "$work/ports")
check "first repo gets the base port" "8800" "$first"
run "$work/tmux" nested
check "second repo gets the next port" "8801" "$(awk '$1 == "nested" { print $2 }' "$work/ports")"
run "$work/tmux" toplevel
check "re-opening reuses the same port" "8800" "$(awk '$1 == "toplevel" { print $2 }' "$work/ports")"

# --- a new session is created with a prompt over pax in window 0 -------------
rm -f "$work/ports"
run "$work/tmux" toplevel
check "creates a detached session named for the repo" "1" \
  "$(grep -c -- "new-session -d -P -F #{window_id} -s toplevel -c $src/toplevel -n pax" "$work/calls" || true)"
check "leaves the first pane a bare shell at the repo root" "1" \
  "$(grep -c -- "^new-session -d -P -F #{window_id} -s toplevel -c $src/toplevel -n pax$" "$work/calls" || true)"
check "splits pax in below the prompt, by window id" "1" \
  "$(grep -c -- "split-window -v -l 70% -P -F #{pane_id} -t @9 -c $src/toplevel " "$work/calls" || true)"
check "targets no hardcoded index" "0" \
  "$(grep -c -e ':0\.' -e '=toplevel:0' "$work/calls" || true)"
check "launches pax with a stable session id" "1" \
  "$(grep -c -- '--session-id pax-toplevel' "$work/calls" || true)"
check "pins the computer port" "1" "$(grep -c 'PAX_COMPUTER_PORT=8800' "$work/calls" || true)"
check "focuses the pax pane by id" "1" \
  "$(grep -c -- 'select-pane -t %7' "$work/calls" || true)"

# --- persona- is stripped from the session name, not from the lookup key -----
rm -f "$work/ports"
run "$work/tmux" persona-web
check "strips persona- from the session name" "1" \
  "$(grep -c -- "new-session -d -P -F #{window_id} -s web -c $src/persona-web -n pax" "$work/calls" || true)"
check "keys the port registry on the full basename" "8800" \
  "$(awk '$1 == "persona-web" { print $2 }' "$work/ports")"
check "keys the pax session id on the full basename" "1" \
  "$(grep -c -- '--session-id pax-persona-web' "$work/calls" || true)"
check "focuses the stripped session name" "1" \
  "$(grep -c -- 'switch-client -t =web' "$work/calls" || true)"

run "$work/tmux-existing" persona-web
check "probes the stripped name when checking for reuse" "1" \
  "$(grep -c -- 'has-session -t =web' "$work/calls" || true)"
check "does not recreate an existing stripped session" "0" \
  "$(grep -c -- 'new-session' "$work/calls" || true)"

# --- an existing session is attached, not recreated --------------------------
run "$work/tmux-existing" toplevel
check "does not recreate an existing session" "0" "$(grep -c -- 'new-session' "$work/calls" || true)"
check "switches to the existing session" "1" "$(grep -c -- 'switch-client -t =toplevel' "$work/calls" || true)"

# --- an unknown repo is an error, not a silent no-op -------------------------
if run "$work/tmux" nosuchrepo; then
  check "unknown repo fails" "nonzero exit" "exit 0"
else
  check "unknown repo fails" "nonzero exit" "nonzero exit"
fi

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
