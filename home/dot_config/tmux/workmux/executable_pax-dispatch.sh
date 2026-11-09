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
# The prompt is normally committed on the branch. A repo that gitignores
# docs/superpowers keeps the planning docs out of git on purpose, and then the
# prompt is taken from disk in this worktree instead: the lane runs here and the
# lead gets an absolute path, so the file only has to exist, not be committed.
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

# Pathspecs below are relative to the cwd, so run from the worktree root even
# when invoked from a subdirectory of it.
cd "$worktree"

base=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo origin/main)
git rev-parse --verify --quiet "$base" >/dev/null 2>&1 || base=main

prompts=$(git diff --name-only "$base...HEAD" -- "$prompt_dir" || true)
source=committed
where="adds"
if [ -z "$prompts" ]; then
  # Nothing committed: look for a gitignored prompt on disk. Ignored files are
  # per-worktree, so anything listed was written in this one. Only *.md counts,
  # so a globally ignored .DS_Store is not mistaken for a second prompt.
  prompts=$(git ls-files --others --ignored --exclude-standard -- "$prompt_dir/*.md")
  source=ignored
  where="has (gitignored, on disk)"
fi
count=$(printf '%s' "$prompts" | grep -c . || true)

if [ "$count" -eq 0 ]; then
  # A prompt that is on disk and could be committed but wasn't: the planning
  # docs belong in the PR, so say what to do rather than "write one first".
  untracked=$(git ls-files --others --exclude-standard -- "$prompt_dir")
  if [ -n "$untracked" ]; then
    fail "the prompt under $prompt_dir is not committed -- commit it before dispatching:
$untracked"
  fi
  fail "branch '$branch' adds no file under $prompt_dir -- write the pax prompt first"
fi
if [ "$count" -gt 1 ]; then
  fail "branch '$branch' $where $count files under $prompt_dir, expected exactly one:
$prompts"
fi

if [ "$source" = committed ]; then
  docs_line="where the spec, plan and prompt are already committed."
  pr_line="so everything reaches review in one PR"
else
  docs_line="where the spec, plan and prompt are on disk but not committed: this repo gitignores $prompt_dir, so leave them uncommitted and never force-add them."
  pr_line="so the implementation reaches review in one PR"
fi

# The @ path must be ABSOLUTE. Both git listings yield a path relative to the
# worktree, but the lead's cwd is the repo root on main -- where the prompt
# does not exist, because it lives on the planning branch or only in this
# worktree. A relative path silently fails to resolve there.
instruction="Execute the plan in @$worktree/$prompts.
Delegate it with workingDir=\"$worktree\" so the work happens in that existing worktree on branch $branch, $docs_line
Do not provision a new worktree: implementation commits must land on branch $branch $pr_line."

if [ -n "${PAX_DISPATCH_DRY_RUN:-}" ]; then
  printf '%s\n' "$instruction"
  exit 0
fi

"$workmux_bin" send "$repo" "$instruction" || fail "workmux send to '$repo' failed"
"$tmux_bin" select-window -t :pax || true
