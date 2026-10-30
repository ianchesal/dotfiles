#!/usr/bin/env bash
#
# Remove the focused worktree workspace and its branch -- the herdr twin of
# `workmux remove`, the undo of add-worktree.sh.
#
# Bound in config.toml as a popup. `herdr worktree remove` would leave the
# branch, and it closes the workspace this popup runs in -- which kills the
# popup before it can delete the branch. So git removes the checkout and the
# branch, and the workspace is closed last. Every destructive step asks first:
# the removal itself, forcing past uncommitted or untracked files, and deleting
# a branch git calls unmerged.
#
# Seams for script/tests/herdr-remove-worktree.test.sh:
#   HERDR_BIN                 -- herdr executable (default: $HERDR_BIN_PATH, else herdr on PATH)
#   HERDR_ACTIVE_WORKSPACE_ID -- the workspace to remove; herdr sets it for popups

set -euo pipefail

# herdr injects its binary path, but a brew upgrade under a running server
# leaves it pointing at a deleted Cellar path -- fall back to PATH.
herdr=${HERDR_BIN:-${HERDR_BIN_PATH:-herdr}}
[ -x "$herdr" ] || herdr=herdr

pause() {
  if [ -t 0 ]; then
    echo
    echo "Press any key to close."
    read -r -n 1 -s
  fi
}

fail() {
  echo "remove-worktree: $*" >&2
  pause
  exit 1
}

# y/N prompt; anything but y or yes (including EOF) is no.
confirm() {
  local answer
  printf '%s [y/N] ' "$1"
  read -r answer || true
  case $answer in
    [yY] | [yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

ws=${HERDR_ACTIVE_WORKSPACE_ID:?remove-worktree: no focused workspace}

info=$("$herdr" workspace list |
  jq -c --arg w "$ws" '.result.workspaces[] | select(.workspace_id == $w) | .worktree // empty')
[ "$(jq -r '.is_linked_worktree // false' <<<"$info" 2>/dev/null)" = true ] ||
  fail "this workspace is not a worktree; switch to the one to remove"
path=$(jq -r '.checkout_path' <<<"$info")
root=$(jq -r '.repo_root' <<<"$info")
# Empty on a detached HEAD: there is no branch to delete.
branch=$(git -C "$path" branch --show-current 2>/dev/null || true)

echo "worktree: $path"
echo "branch:   ${branch:-(detached HEAD)}"
confirm 'Remove this worktree and its branch?' || exit 0

# Forcing would discard these, so show them and ask before doing it.
force=
if [ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then
  git -C "$path" status --short
  confirm 'Uncommitted or untracked files above will be lost. Remove anyway?' || exit 0
  force=--force
fi
# git -C "$root" from here on: the popup's cwd is the checkout being deleted.
git -C "$root" worktree remove ${force:+"$force"} "$path" || fail "could not remove $path"

if [ -n "$branch" ] && ! git -C "$root" branch -d "$branch" 2>/dev/null; then
  if confirm "Branch $branch is not fully merged. Delete it anyway?"; then
    git -C "$root" branch -D "$branch" || fail "could not delete branch $branch"
  fi
fi

# Last: closing the workspace ends this popup.
"$herdr" workspace close "$ws" >/dev/null || fail "worktree removed but workspace $ws did not close"
