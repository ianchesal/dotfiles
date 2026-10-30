#!/usr/bin/env bash
#
# Tests for home/dot_config/herdr/executable_remove-worktree.sh. Drives the
# script against a fake herdr and real worktrees of a scratch git repo, with
# the y/N answers fed on stdin.
#
# Run: script/tests/herdr-remove-worktree.test.sh

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
subject=$here/../../home/dot_config/herdr/executable_remove-worktree.sh

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
# macOS mktemp hands back /var/..., which git reports as /private/var/...
work=$(cd "$work" && pwd -P)

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

gitq() { git -c user.name=t -c user.email=t@t "$@"; }

repo=$work/src/demo
gitq init -q -b main "$repo"
gitq -C "$repo" commit -q --allow-empty -m init

# A worktree on a new branch, optionally with a commit main lacks (unmerged)
# or an untracked file (dirty).
add_wt() {
  local branch=$1 kind=${2:-}
  gitq -C "$repo" worktree add -q "${repo}__worktrees/$branch" -b "$branch"
  case $kind in
    unmerged) gitq -C "${repo}__worktrees/$branch" commit -q --allow-empty -m wip ;;
    dirty) touch "${repo}__worktrees/$branch/junk" ;;
  esac
}

# A fake herdr that records its argv one call per line. `workspace list`
# reports w1 as the main checkout and w2 as the worktree at $WT_PATH.
cat >"$work/herdr" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$HERDR_CALLS"
if [ "$1 $2" = "workspace list" ]; then
  printf '{"result":{"workspaces":[
    {"workspace_id":"w1","worktree":{"checkout_path":"%s","repo_root":"%s","is_linked_worktree":false}},
    {"workspace_id":"w2","worktree":{"checkout_path":"%s","repo_root":"%s","is_linked_worktree":true}},
    {"workspace_id":"w3","worktree":null}]}}\n' "$REPO" "$REPO" "$WT_PATH" "$REPO"
fi
FAKE
chmod +x "$work/herdr"

# run <workspace> <branch> <answers...>
run() {
  local ws=$1 branch=$2
  shift 2
  : >"$work/calls"
  printf '%s\n' "$@" | REPO=$repo WT_PATH=${repo}__worktrees/$branch HERDR_CALLS=$work/calls \
    HERDR_BIN=$work/herdr HERDR_ACTIVE_WORKSPACE_ID=$ws "$subject" >"$work/out" 2>"$work/err"
}

has_branch() { git -C "$repo" show-ref -q --verify "refs/heads/$1" && echo yes || echo no; }
has_dir() { [ -d "${repo}__worktrees/$1" ] && echo yes || echo no; }
closed() { grep -c -- '^workspace close w2$' "$work/calls" || true; }

echo "herdr-remove-worktree"

# --- a clean, merged worktree goes after one yes ------------------------------
add_wt merged
run w2 merged y
check "removes the checkout" "no" "$(has_dir merged)"
check "deletes the merged branch" "no" "$(has_branch merged)"
check "closes the workspace" "1" "$(closed)"
check "closes the workspace last" "workspace close w2" "$(tail -n 1 "$work/calls")"

# --- declining the first prompt touches nothing -------------------------------
add_wt declined
run w2 declined n
check "a no keeps the checkout" "yes" "$(has_dir declined)"
check "a no keeps the branch" "yes" "$(has_branch declined)"
check "a no keeps the workspace" "0" "$(closed)"

run w2 declined ''
check "a bare enter is a no" "yes" "$(has_dir declined)"

# --- an unmerged branch needs its own yes -------------------------------------
add_wt unmerged unmerged
run w2 unmerged y y
check "removes the unmerged checkout" "no" "$(has_dir unmerged)"
check "deletes an unmerged branch on a second yes" "no" "$(has_branch unmerged)"
check "asks before deleting an unmerged branch" "1" "$(grep -c 'not fully merged' "$work/out" || true)"

add_wt keepme unmerged
run w2 keepme y n
check "removes the checkout even when the branch is kept" "no" "$(has_dir keepme)"
check "a no keeps the unmerged branch" "yes" "$(has_branch keepme)"
check "still closes the workspace" "1" "$(closed)"

# --- a dirty worktree shows what would be lost and needs its own yes ----------
add_wt dirty dirty
run w2 dirty y n
check "a no keeps the dirty checkout" "yes" "$(has_dir dirty)"
check "shows the files at stake" "1" "$(grep -c 'junk' "$work/out" || true)"
check "a no on force keeps the workspace" "0" "$(closed)"

run w2 dirty y y
check "forces past untracked files on a yes" "no" "$(has_dir dirty)"
check "deletes the forced worktree's branch" "no" "$(has_branch dirty)"

# --- only a linked worktree can be removed ------------------------------------
for ws in w1 w3; do
  if run "$ws" none y; then
    check "refuses workspace $ws" "nonzero exit" "exit 0"
  else
    check "refuses workspace $ws" "nonzero exit" "nonzero exit"
  fi
done
check "the main checkout is untouched" "yes" "$([ -d "$repo/.git" ] && echo yes || echo no)"
check "main survives a refusal" "yes" "$(has_branch main)"

if [ "$failures" -gt 0 ]; then
  printf '  %d failure(s)\n' "$failures"
  exit 1
fi
