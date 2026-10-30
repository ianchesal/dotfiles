#!/usr/bin/env bash
#
# Tests for home/dot_config/herdr/executable_open-repo.sh. Drives the script
# against a fake herdr, a fake fzf and a scratch ~/src so no real workspace is
# created.
#
# Run: script/tests/herdr-open-repo.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/herdr/executable_open-repo.sh

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

src=$work/src
mkdir -p "$src/toplevel/.git" "$src/org/nested/.git" "$src/org/nested__worktrees/wt/.git" \
  "$src/persona-web/.git"

# A fake herdr that records its argv one call per line. `workspace list`
# answers with $WORKSPACES, a JSON array, defaulting to none open.
mkdir -p "$work/bin"
cat >"$work/bin/herdr" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$HERDR_CALLS"
if [ "$1 $2" = "workspace list" ]; then
  printf '{"result":{"workspaces":%s}}\n' "${WORKSPACES:-[]}"
fi
FAKE
chmod +x "$work/bin/herdr"

# A fake fzf that saves the candidate list and picks $FZF_PICK.
cat >"$work/bin/fzf" <<'FAKE'
#!/usr/bin/env bash
cat >"$FZF_INPUT"
[ -n "${FZF_PICK:-}" ] || exit 130
echo "$FZF_PICK"
FAKE
chmod +x "$work/bin/fzf"

run() {
  : >"$work/calls"
  PATH=$work/bin:$PATH HERDR_CALLS=$work/calls FZF_INPUT=$work/fzf-input SRC_ROOT=$src \
    HERDR_BIN=$work/bin/herdr "$subject" "$@" >"$work/out" 2>"$work/err"
}

echo "herdr-open-repo"

# --- fzf sees both depths, relative to ~/src, and no worktree storage ---------
FZF_PICK=toplevel run
check "offers repos at both depths" "org/nested persona-web toplevel" "$(tr '\n' ' ' <"$work/fzf-input" | sed 's/ $//')"
check "creates a workspace for the pick" "1" \
  "$(grep -c -- "^workspace create --cwd $src/toplevel --label toplevel --focus$" "$work/calls" || true)"

# --- a cancelled picker does nothing -----------------------------------------
FZF_PICK='' run || true
check "cancelling fzf calls no herdr" "0" "$(wc -l <"$work/calls" | tr -d ' ')"

# --- persona- is stripped from the label, not the path -----------------------
run persona-web
check "strips persona- from the label" "1" \
  "$(grep -c -- "^workspace create --cwd $src/persona-web --label web --focus$" "$work/calls" || true)"

# --- a nested repo is addressed by its relative path -------------------------
run org/nested
check "labels a nested repo by basename" "1" \
  "$(grep -c -- "^workspace create --cwd $src/org/nested --label nested --focus$" "$work/calls" || true)"

# --- an already open repo is focused, not recreated --------------------------
# herdr reports a checkout path only for a workspace that has worktrees.
WORKSPACES="[{\"workspace_id\":\"w7\",\"label\":\"renamed\",\"worktree\":{\"checkout_path\":\"$src/toplevel\"}}]" run toplevel
check "focuses the workspace on that checkout" "1" "$(grep -c -- '^workspace focus w7$' "$work/calls" || true)"
check "does not create a second workspace" "0" "$(grep -c -- 'workspace create' "$work/calls" || true)"

# A plain workspace has no checkout path, so it is matched by label.
WORKSPACES='[{"workspace_id":"w5","label":"web","worktree":null}]' run persona-web
check "focuses a plain workspace by label" "1" "$(grep -c -- '^workspace focus w5$' "$work/calls" || true)"
check "does not recreate a plain workspace" "0" "$(grep -c -- 'workspace create' "$work/calls" || true)"

# A worktree workspace named like the repo is not the repo.
WORKSPACES="[{\"workspace_id\":\"w9\",\"label\":\"toplevel\",\"worktree\":{\"checkout_path\":\"$src/x__worktrees/toplevel\"}}]" run toplevel
check "ignores a worktree workspace sharing the label" "1" "$(grep -c -- 'workspace create' "$work/calls" || true)"

WORKSPACES="[{\"workspace_id\":\"w7\",\"label\":\"toplevel\",\"worktree\":null}]" run persona-web
check "an open repo elsewhere does not block creation" "1" "$(grep -c -- 'workspace create' "$work/calls" || true)"

# --- an unknown repo is an error, not a workspace on a bad path --------------
if run nosuchrepo; then
  check "unknown repo fails" "nonzero exit" "exit 0"
else
  check "unknown repo fails" "nonzero exit" "nonzero exit"
fi
check "unknown repo creates nothing" "0" "$(grep -c -- 'workspace create' "$work/calls" || true)"

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
