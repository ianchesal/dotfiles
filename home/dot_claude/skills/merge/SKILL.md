---
name: merge
description: Commit, rebase, and merge the current worktree branch, then remove its worktree and herdr workspace.
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
---

**Arguments:** `$ARGUMENTS`

Check the arguments for flags:

- `--keep`, `-k` → merge, but keep the worktree, branch and herdr workspace
- `--no-verify`, `-n` → pass `--no-verify` to the commit and merge (skips git hooks)

Strip all flags from arguments.

This finishes work on the current branch by:

1. Committing all uncommitted changes
2. Rebasing onto the base branch
3. Fast-forwarding the base branch to this branch
4. Removing the worktree, the branch and this herdr workspace (unless `--keep`)

## Step 0: Where you are

```bash
branch=$(git branch --show-current)
common=$(git rev-parse --path-format=absolute --git-common-dir)
root=$(dirname "$common")                 # the main checkout
path=$(git rev-parse --show-toplevel)     # this worktree
```

If `branch` is empty (detached HEAD) or `path` equals `root` (you are in the
main checkout, not a worktree), stop and tell the user: this skill merges a
worktree branch into its base.

## Step 1: Commit

Check for staged, unstaged, and untracked changes with `git status --porcelain`.
If there are any, stage them all with `git add -A`, review the staged diff, and
commit. Use lowercase, imperative mood, no conventional-commit prefixes. Never
commit a `STATUS.md`. Skip this step if the working tree is clean.

## Step 2: Rebase

Find the base branch, first match wins:

```bash
git config --get "branch.$branch.herdr-base" ||
  git config --get "branch.$branch.workmux-base" ||
  echo main
```

Rebase onto the local base branch (do NOT fetch from origin first):

```bash
git rebase <base-branch>
```

IMPORTANT: Do NOT run `git fetch`. Do NOT rebase onto `origin/<branch>`. Only
rebase onto the local branch name (e.g., `git rebase main`, not
`git rebase origin/main`).

If conflicts occur:

- BEFORE resolving any conflict, understand what changes were made to each
  conflicting file in the base branch
- For each conflicting file, run `git log -p -n 3 <base-branch> -- <file>` to
  see recent changes to that file in the base branch
- The goal is to preserve BOTH the base branch's changes AND this branch's
  changes
- After resolving each conflict, stage the file and continue with
  `git rebase --continue`
- If a conflict is too complex or unclear, ask for guidance before proceeding

## Step 3: Merge

Fast-forward the base branch. Where it is checked out decides how:

```bash
git worktree list --porcelain   # which checkout, if any, has <base-branch>
```

- **Checked out in the main checkout** (`root`):
  `git -C "$root" merge --ff-only [--no-verify] "$branch"`
- **Not checked out anywhere**: `git -C "$root" fetch . "$branch:<base-branch>"`
  (moves the ref, fast-forward only)
- **Checked out in another worktree**: stop and ask the user. Don't touch
  someone else's checkout.

If the fast-forward is refused, the base branch moved since the rebase: go back
to Step 2. If the main checkout has uncommitted changes in the way, stop and ask.

Then, if `HERDR_ENV` is 1, tell the user it landed:

```bash
herdr notification show "Merged $branch" --body "into <base-branch>" --sound done
```

With `--keep`, stop here and report what was merged.

## Step 4: Clean up

Everything below runs from the main checkout, because this worktree is about to
be deleted. Closing the herdr workspace ends this session, so it goes last.

```bash
cd "$root"
git worktree remove "$path"
git branch -d "$branch"
```

Never pass `--force` to either. If `worktree remove` refuses (untracked or
ignored files left behind), list them and ask the user. `branch -d` cannot fail
after a successful fast-forward. If it does, stop and report.

Before closing the workspace, report what was merged (branch, base, commits) in
your reply: once the workspace closes, nothing more can be said. Then close it
only if it really is this worktree's workspace:

```bash
herdr workspace get "$HERDR_WORKSPACE_ID" |
  jq -e --arg p "$path" '.result.workspace.worktree.checkout_path == $p' >/dev/null &&
  herdr workspace close "$HERDR_WORKSPACE_ID"
```

If the check fails, leave the workspace open and say so.
