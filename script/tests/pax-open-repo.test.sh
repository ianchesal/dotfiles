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
cat >"$work/tmux" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$TMUX_CALLS"
[ "${1:-}" = "has-session" ] && exit 1
exit 0
FAKE
chmod +x "$work/tmux"

# A fake tmux that reports the session already exists.
cat >"$work/tmux-existing" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$TMUX_CALLS"
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

# --- a new session is created with pax in window 0 ---------------------------
rm -f "$work/ports"
run "$work/tmux" toplevel
check "creates a detached session named for the repo" "1" \
  "$(grep -c -- "new-session -d -s toplevel -c $src/toplevel -n pax" "$work/calls" || true)"
check "launches pax with a stable session id" "1" \
  "$(grep -c -- '--session-id pax-toplevel' "$work/calls" || true)"
check "pins the computer port" "1" "$(grep -c 'PAX_COMPUTER_PORT=8800' "$work/calls" || true)"

# --- persona- is stripped from the session name, not from the lookup key -----
rm -f "$work/ports"
run "$work/tmux" persona-web
check "strips persona- from the session name" "1" \
  "$(grep -c -- "new-session -d -s web -c $src/persona-web -n pax" "$work/calls" || true)"
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
