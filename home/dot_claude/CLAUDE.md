# Workflow Management

## Communication Style
- **Links are always full, bare URLs.** Write `https://github.com/persona-id/persona-infrastructure/pull/19665`,
  never `persona-infrastructure#19665`, `#19665`, `owner/repo#N`, `[text](url)` or any other shorthand or markdown
  link — the user works in tmux over SSH where those render as styled but unclickable text. Applies to PRs, issues,
  commits, Jira tickets, Slack messages, docs, everything: if you reference it, print the whole URL
- **Before tool calls**: Tell the user what you're about to do in a single concise sentence
- **During execution**: Provide brief progress updates without asking for permission
- **After major steps**: Update STATUS.md (see below) and show progress
- **When blocked**: Update STATUS.md (`State: blocked`, the exact question under
  `Waiting on me`), then explain the issue and ask for guidance

## Status file
For any task longer than a few minutes, maintain `STATUS.md` in the repo/worktree root.
Update it before you stop, whenever you're blocked on me, and after each meaningful step.
Keep it short and overwrite stale content.

STATUS.md is the canonical record of progress. The in-session todo list is a scratch
aid for the current session only. If a step, decision or gotcha matters beyond this
session, it goes in STATUS.md, and when the two disagree STATUS.md wins.
STATUS.md is globally gitignored; never commit it or force-add it. Format:

```
# <task name>
**State:** working | blocked | done
**Goal:** one line
**Done so far:** bullets
**Waiting on me:** the specific question or decision, or "nothing"
**Next step:** one line
**Gotchas:** anything I'd need to know to pick this up cold
```

## Handing off tasks to me
Use this when a step needs access only my work MacBook has: gcloud commands
that need elevated permissions not available from my workstation, browser-based
interactions, interactions that require elevated okta permissions. Don't hand
off anything you can do yourself.

This only applies when you're running on Linux (my workstation). On macOS you're
already on a Mac: never write a handoff script there. Run the step yourself if you
can, otherwise ask me.

`~/src/handoff/<task>/` syncs both ways between this workstation and my MacBook.
Name `<task>` `<repo>-<branch>` (e.g. `persona-infrastructure-fix-dns`) so concurrent
sessions never share a folder; if one already exists for something else, add a suffix.
To hand off:
1. Write `~/src/handoff/<task>/<script>.sh`. It runs on **macOS, zsh, BSD userland**.
   Start it with `#!/bin/zsh` and write zsh, not bash: no bash 4+ features
   (`mapfile`, `declare -A`), no GNU-only flags, no hardcoded /home paths; resolve
   paths relative to the script's own directory.
2. Start the script with a comment block: what it does, why you need it, what it
   changes, and whether it's safe to re-run. Keep it short and readable — I review
   every script before running it. No obfuscation, no curl-pipe-to-shell, no
   fetching remote code.
3. Before doing anything else, the script deletes any stale `exit_code` and
   `<script>.out` in its folder, so a leftover from an earlier run never looks like
   a finished one. It then captures its own output: everything to `<script>.out` in
   the same folder, and the exit code to `exit_code` as the last thing it writes.
4. That folder syncs to every machine. The script must never print credentials,
   tokens, keys or other secrets to its output: redact them, or report only
   whether a value was present.
5. Update STATUS.md: State: blocked, Waiting on me: "run ~/src/handoff/<task>/<script>.sh".
   Then stop. Don't poll.
6. When I tell you it's done (or `exit_code` exists), read `<script>.out` and continue.
   Once you've read the result and no longer need the folder, delete
   `~/src/handoff/<task>/` so its output doesn't keep syncing.

# Technical Preferences

## Security & Safety
- NEVER store secrets in files that might get checked in to git
- NEVER run commands with sudo
- Be security conscious in your answers
- If you do not know the answer say "I don't know the answer" and don't guess
- If you are running as the root user, stop and kill yourself

## Code Investigation
- Before deep root-cause analysis, run `git pull` (or confirm working tree is current) so the investigation isn't based on stale code
- When debugging hard-to-reproduce issues (e.g., post-sleep hangs, race conditions), explicitly state the hypothesis being tested and ask the user to verify the fix BEFORE moving to the next attempt—avoid stacking speculative fixes

## Editing Notes & Documents
- When the user provides a name, company, or proper noun, verify spelling against existing context (prior notes, calendar entries) before propagating it across a document

## Code Review
- When leaving review comments as part of a code review use the [Conventional Comments](https://conventionalcomments.org/) style
