#!/usr/bin/env bash
#
# Make a git worktree for a branch, open it as a herdr workspace and start
# claude in it -- the herdr twin of tmux's prefix+w "add" (workmux add).
#
# Bound in config.toml as a popup, so it runs in the focused pane's directory.
# Works from the repo or any of its worktrees: herdr only creates worktrees from
# the main checkout, so the root is resolved through git's common dir. A new
# branch is cut from the current HEAD; an existing one is checked out. The
# checkout lands in <repo>__worktrees/<branch>, the layout workmux uses, with
# any / in the branch flattened to -.
#
# claude stopping at its "trust this folder" prompt counts as started: every
# new worktree path asks once.
#
# Seams for script/tests/herdr-add-worktree.test.sh:
#   HERDR_BIN -- herdr executable (default: $HERDR_BIN_PATH, else herdr on PATH)
#   BRANCH    -- skip the prompt and use this branch

set -euo pipefail

# herdr injects its binary path, but a brew upgrade under a running server
# leaves it pointing at a deleted Cellar path -- fall back to PATH.
herdr=${HERDR_BIN:-${HERDR_BIN_PATH:-herdr}}
[ -x "$herdr" ] || herdr=herdr

fail() {
  echo "add-worktree: $*" >&2
  if [ -t 0 ]; then
    echo
    echo "Press any key to close."
    read -r -n 1 -s
  fi
  exit 1
}

# herdr agent names must match [a-z][a-z0-9_-]{0,31}.
agent_name() {
  local name
  name=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]+/-/g')
  case $name in
    [a-z]*) ;;
    *) name=wt-$name ;;
  esac
  printf '%s\n' "${name:0:32}"
}

common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) ||
  fail "$PWD is not in a git repo"
root=$(dirname "$common")

branch=${BRANCH:-}
if [ -z "$branch" ]; then
  printf 'Branch: '
  read -r branch || true
fi
[ -n "$branch" ] || exit 0

out=$("$herdr" worktree create --cwd "$root" --branch "$branch" \
  --path "${root}__worktrees/${branch//\//-}" --focus 2>&1) ||
  fail "$(jq -r '.error.message' <<<"$out" 2>/dev/null || echo "$out")"
pane=$(jq -r '.result.root_pane.pane_id' <<<"$out")

echo 'Starting claude...'
out=$("$herdr" agent start "$(agent_name "$branch")" --kind claude --pane "$pane" -- --permission-mode auto 2>&1) || {
  [ "$(jq -r '.error.code // empty' <<<"$out" 2>/dev/null)" = agent_not_ready ] ||
    fail "worktree is open but claude did not start: $out"
}
