#!/usr/bin/env bash
#
# Tests for home/dot_config/tmux/workmux/executable_open-repo.sh. Drives the
# script against a fake tmux and a scratch ~/src so no real session is created.
#
# Run: script/tests/open-repo.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/tmux/workmux/executable_open-repo.sh

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
case "${1:-}" in
  has-session) exit 1 ;;
esac
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
  "$src/persona-web/.git" "$src/org/persona-pax/.git"

run() {
  : >"$work/calls"
  TMUX_CALLS=$work/calls SRC_ROOT=$src TMUX_BIN=${1:-$work/tmux} \
    "$subject" "${@:2}" >"$work/out" 2>"$work/err"
}

echo "open-repo"

# --- enumeration finds both depths and excludes worktree storage -------------
OPEN_REPO_LIST_ONLY=1 SRC_ROOT=$src "$subject" >"$work/list" 2>&1
check "lists both repo depths" "nested persona-pax persona-web toplevel" \
  "$(awk '{print $1}' "$work/list" | sort | tr '\n' ' ' | sed 's/ $//')"
check "excludes __worktrees" "0" "$(grep -c '__worktrees' "$work/list" || true)"

# --- a new session is one bare shell at the repo root ------------------------
run "$work/tmux" toplevel
check "creates a detached session named for the repo, running nothing" "1" \
  "$(grep -c -- "^new-session -d -s toplevel -c $src/toplevel$" "$work/calls" || true)"
check "creates no split" "0" "$(grep -c -- 'split-window' "$work/calls" || true)"
check "launches no pi" "0" "$(grep -c -e '--session-id' -e 'PAX_COMPUTER_PORT' "$work/calls" || true)"
check "switches to the new session" "1" "$(grep -c -- 'switch-client -t =toplevel' "$work/calls" || true)"

# --- persona- is stripped from the session name, not from the lookup key -----
run "$work/tmux" persona-web
check "strips persona- from the session name" "1" \
  "$(grep -c -- "^new-session -d -s web -c $src/persona-web$" "$work/calls" || true)"
check "focuses the stripped session name" "1" \
  "$(grep -c -- 'switch-client -t =web' "$work/calls" || true)"

run "$work/tmux-existing" persona-web
check "probes the stripped name when checking for reuse" "1" \
  "$(grep -c -- 'has-session -t =web' "$work/calls" || true)"
check "does not recreate an existing stripped session" "0" \
  "$(grep -c -- 'new-session' "$work/calls" || true)"

# --- a repo that would strip to "pax" must not land in the lead's session ----
run "$work/tmux" persona-pax
check "keeps the full name when stripping would give pax" "1" \
  "$(grep -c -- "^new-session -d -s persona-pax -c $src/org/persona-pax$" "$work/calls" || true)"
check "never probes the lead's session" "0" "$(grep -c -- '=pax$' "$work/calls" || true)"

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
