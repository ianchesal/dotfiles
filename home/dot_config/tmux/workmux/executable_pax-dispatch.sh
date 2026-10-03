#!/usr/bin/env bash
#
# Hand the current Claude planning worktree to this repo's pax lead.
#
# pax baselines its own lane worktrees off origin/main, so the only way the
# planning artifacts (spec, plan, prompt) reach the implementation is to point a
# lane at THIS worktree via workingDir. Implementation commits then land on the
# planning branch and everything reaches review in one PR -- protected main is
# never merged into. See docs/superpowers/specs/
# 2026-09-21-pax-tmux-workflow-design.md.
#
# The instruction below names workingDir explicitly on purpose: a delegation
# without one makes pax provision a worktree off origin/main that workmux cannot
# see.
#
# Seams for script/tests/pax-dispatch.test.sh:
#   WORKMUX_BIN          -- workmux executable (default: workmux)
#   TMUX_BIN             -- tmux executable (default: tmux)
#   PAX_DISPATCH_DRY_RUN -- when non-empty, print the instruction and stop

set -euo pipefail

workmux_bin=${WORKMUX_BIN:-workmux}
tmux_bin=${TMUX_BIN:-tmux}
prompt_dir=docs/superpowers/prompts

fail() {
  echo "pax-dispatch: $*" >&2
  exit 1
}

git rev-parse --git-dir >/dev/null 2>&1 || fail "not a git repository"

worktree=$(git rev-parse --show-toplevel)
branch=$(git rev-parse --abbrev-ref HEAD)

# The first entry of `git worktree list` is always the main working tree; its
# basename is the repo name, which is also workmux's handle for the is_main
# entry and therefore the target of `workmux send`.
main_tree=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
repo=$(basename "$main_tree")

[ "$worktree" != "$main_tree" ] ||
  fail "this is the main checkout, not a planning worktree -- dispatch from the worktree window"

base=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo origin/main)
git rev-parse --verify --quiet "$base" >/dev/null 2>&1 || base=main

prompts=$(git diff --name-only "$base...HEAD" -- "$prompt_dir" || true)
count=$(printf '%s' "$prompts" | grep -c . || true)

if [ "$count" -eq 0 ]; then
  # A gitignored prompt dir looks identical to a missing prompt from here, and
  # is the more confusing failure -- the file is right there on disk. The spec's
  # precondition: pax reads the prompt from the branch, so it must be committed.
  if git check-ignore -q "$prompt_dir" 2>/dev/null; then
    fail "$prompt_dir is gitignored in this repo, so the prompt can never reach the branch -- un-ignore it before dispatching"
  fi
  fail "branch '$branch' adds no file under $prompt_dir -- write the pax prompt first"
fi
if [ "$count" -gt 1 ]; then
  fail "branch '$branch' adds $count files under $prompt_dir, expected exactly one:
$prompts"
fi

# The @ path must be ABSOLUTE. `git diff --name-only` yields a path relative to
# the worktree, but the lead's cwd is the repo root on main -- where the prompt
# does not exist, because it is committed on the planning branch. A relative
# path silently fails to resolve there.
instruction="Execute the plan in @$worktree/$prompts.
Delegate it with workingDir=\"$worktree\" so the work happens in that existing worktree on branch $branch, where the spec, plan and prompt are already committed.
Do not provision a new worktree: implementation commits must land on branch $branch so everything reaches review in one PR."

if [ -n "${PAX_DISPATCH_DRY_RUN:-}" ]; then
  printf '%s\n' "$instruction"
  exit 0
fi

"$workmux_bin" send "$repo" "$instruction" || fail "workmux send to '$repo' failed"
"$tmux_bin" select-window -t :pax || true
