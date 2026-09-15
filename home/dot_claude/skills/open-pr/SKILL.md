---
name: open-pr
description: Write a PR description using conversation context and open PR upstream in Github.
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
---

## 1. Commit first

Run `git status`. If anything is uncommitted, ask whether it belongs in this PR,
then commit. Never gather the diff from a dirty tree — the description ends up
describing code the branch doesn't contain.

## 2. Gather context

```bash
git fetch origin              # without this, every command below reads a stale base
base=$(git rev-parse --abbrev-ref origin/HEAD)   # errors? git remote set-head origin -a

gh pr view --json url,state                      # already open? update it, don't open a second
git merge-tree --write-tree --name-only "$base" HEAD   # exit 1 = will conflict, lists the files
git log  "$base"..HEAD --format='%s'             # two dots — three includes base-only commits
git diff "$base"...HEAD --stat
git diff "$base"...HEAD
```

Read changed files where the diff alone doesn't explain the change. Prefer what
the conversation already established over re-deriving intent from the diff.

`merge-tree` is read-only — it writes no files and touches neither the working tree
nor the index. Being behind `$base` is fine on its own; only a conflict is a stop.
If it exits 1, name the conflicted files and stop. Do not rebase to fix it: that
rewrites an already-pushed branch and strands the repo mid-rebase if resolution goes
wrong. Hand off to the `rebase` skill, then start this one again from step 1.

## 3. Write the description

```markdown
## Summary

[1-2 sentences: what changed and why]

## Changes

- [Key change]
- [Key change]

## Testing

[What you actually ran]
```

Summary is required. Drop `## Changes` for a single-concern PR; drop `## Testing`
if you ran nothing — an empty heading is worse than no heading.

How to write it:

- Write for the reviewer: what changed, why, and where to look hardest.
- Name the thing. "Fixed the pruner" → "`asdf-prune` no longer deletes the in-use
  version when two versions tie."
- Give the *why* as the problem, not the solution. "Version comparison was
  string-based, so `1.10` sorted below `1.9`" beats "improved comparison logic."
- Active voice, present tense, no "we": "Drops the Ruby dependency", not "We have
  removed the Ruby dependency" or "The dependency was removed".
- One idea per sentence. Delete any sentence the PR survives without.
- Never restate the diff file by file. A bullet that is a filename plus "updated"
  is noise.
- Scale to the change. A one-line fix gets two sentences. Do not pad to fill the
  template.
- Include a before/after for UI or performance changes.

Never write: "This PR", "In this change", "It's worth noting", comprehensive,
robust, seamless, leverage, streamline, enhance, ensure that, crucial,
significantly. No emoji. No bold inside bullets.

## 4. Open it

Title: imperative mood, ≤72 chars, no trailing period. Match the repo's existing
title style (`git log "$base" --format='%s' -20`) — only use a `type:` prefix if
the repo already does.

```bash
git push -u origin HEAD

gh pr create --assignee @me --title "$title" --body-file - <<'EOF'
<body>
EOF
```

Pass the body on stdin with a **quoted** heredoc (`<<'EOF'`). Backticks and `$`
are normal in PR bodies; with `--body "..."` the shell executes them first. This
is the most common way this skill fails.

## 5. Print the URL

End with the URL `gh` printed — the bare `https://github.com/...`, on its own
line, as the last thing in your reply. Not a markdown link, not `[#123](url)`,
not wrapped in prose. The raw string survives copy-paste out of a terminal that
doesn't render links, and gets pasted into Slack and Jira as-is.
