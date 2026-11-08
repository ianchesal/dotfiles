# Running inside herdr

You are in a herdr-managed pane. herdr is the terminal Ian works in: it arranges
terminals into workspaces > tabs > panes and tracks the coding agents running in
them. The `herdr` CLI on PATH talks to this session.

- The `herdr` skill is the reference for command syntax and for pane and agent
  semantics. Load it before your first herdr command in a session. The installed
  binary has the final say: `herdr <group>` with no subcommand prints that
  group's help.
- Never run bare `herdr` (it attaches the TUI), and never probe a mutating
  command by leaving its arguments off (`herdr workspace create` runs with
  defaults).
- Most commands return JSON. Read IDs from the responses; never guess them.

Use herdr in the following ways without being asked.

## Long-running commands go in a side pane

Run dev servers, watchers, log tails, and any test suite or build likely to take
more than about a minute in a sibling pane, not in your own shell and not as a
background job.

- Split from your own pane and keep focus where it is:
  `herdr pane split --current --direction right --cwd "$PWD" --no-focus`.
  Use `--direction down` when your pane is narrow
  (`herdr pane layout --pane "$HERDR_PANE_ID"`). The new ID is
  `.result.pane.pane_id`.
- Name it for what it runs (`herdr pane rename <id> <name>`), then
  `herdr pane run <id> "<command>"`. Follow it with
  `herdr pane wait-output <id> --match <text> --timeout <ms>` and
  `herdr pane read <id> --source recent-unwrapped --lines 200`.
- Reuse a pane you created for later runs rather than splitting again.
- Short commands (git, searches, tests that finish in under a minute) stay in
  your own shell.
- When the task is finished, close the panes you created, except ones running
  something Ian is still using (such as a dev server), and say which you left open.

## STATUS.md shows in the sidebar

A hook copies STATUS.md into herdr's sidebar: the task name becomes this pane's
title, and `State: blocked` shows as a label. When you stop on a MacBook handoff,
it also sends Ian a herdr notification. The hook only sees writes made with the
Write and Edit tools, so always update STATUS.md with those, never with a shell
redirect or heredoc.

## Sibling agents instead of in-process subagents

When Ian asks you to delegate (a review, a second opinion, work in parallel),
start another claude in a herdr pane rather than using the Agent tool, so he can
watch it and talk to it. This changes how you delegate, not when: still only
when asked.

- Split as above, then `herdr agent start <name> --kind claude --pane <id>`.
  Name agents for their job (`reviewer`, `tests-auth`).
- `agent start` returns `agent_not_ready` when claude stops at a startup dialog
  such as folder trust. Don't answer it yourself: tell Ian which pane needs him,
  then `herdr agent wait <name> --until idle --timeout <ms>`.
- Send the task with `herdr agent prompt <name> "<text>" --wait --timeout <ms>`.
  For a long brief, write it to a temp file and prompt the agent to read that file.
- Read results with `herdr agent read <name> --source recent-unwrapped --lines 200`.
  If the agent comes back `blocked`, read its pane and ask Ian before answering
  any approval or question on its behalf.
- Siblings share your checkout, so keep them to read-only work such as reviews.
  Agents that will edit files in parallel each get their own worktree: use the
  `coordinator` skill.
- Close the panes you created once you have the results.

## Safety

- Target your own pane with `--current` or `$HERDR_PANE_ID`, and other panes by
  the ID or agent name from a JSON response. Never act on whichever pane happens
  to have UI focus; it may belong to Ian.
- Pass `--no-focus` so you never pull Ian's view away.
- Never `herdr server stop`, kill herdr, or close a workspace, tab or pane you
  didn't create.
