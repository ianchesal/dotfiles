# Design: a tmux workflow for pax as a per-repo dispatcher

Date: 2026-09-21
Status: approved for planning
Repos in scope: `ianchesal/dotfiles`, `ianchesal/workmux`, `persona-id/pax`

## Problem

The current workflow is: one `main` tmux session with a shell pane at the root of
every active repo, and `workmux` creating a session per worktree for each piece of
feature work, each running Claude. Progress across the machine is read from
`workmux dashboard`.

pax breaks this in three ways:

1. **pax is per-repo, not per-worktree.** It is a long-running dispatcher that
   wants to sit on `main` for hours, be fed work, and decide where and how that
   work happens. Today it is being launched per worktree, which is the wrong
   granularity and wastes its context.
2. **The dashboard goes wrong, not just blind.** workmux's pi status extension
   reports status from the *lead's* `agent_start` / `agent_settled` events. pax
   deliberately defers work to background sidekicks so the lead chat stays
   responsive, so the lead settles almost immediately and workmux reports `done`
   while sidekicks are still working.
3. **Design and planning still belong to Claude.** pax is weak at design and
   planning; those stay a Claude session that ends by writing a prompt for pax.
   That handoff currently has no mechanism.

## Verified constraints

These were read out of the source, not assumed. They constrain the design.

- **pax baselines off `origin/main`, never local main.**
  `baselineFor` (`pax/src/sidekick/lane-worktrees.ts:150`) does
  `git fetch origin` → `origin/HEAD` → `origin/main` → `HEAD`. Merging a planning
  branch into *local* main is therefore invisible to pax. Combined with upstream
  branch protection, local main must never be merged into at all.
- **A `git worktree add` from `origin/main` yields a clean tree.** Uncommitted
  artifacts left in the repo-root working tree do not reach a provisioned lane
  worktree. Only `copyDependencies`
  (`pax/src/sidekick/lane-worktrees.ts:160`) crosses over, and that is configured
  globs for dependency-shaped files.
- **`workingDir` accepts a worktree of the same repo.** `resolveLaneCwd`
  (`pax/src/sidekick/lane-cwd.ts`) documents this as check 4 and resolves the lane
  to that worktree's own root. No worktree is provisioned for such a lane.
- **Lane worktree provisioning is a config seam.** `pax/src/state.ts:919` reads
  `provisionLaneWorktree: config.sidekick.worktrees ? provisionLaneWorktree : undefined`,
  with the comment "Undefined runs lanes in the primary checkout."
  Key `sidekick.worktrees`, default `true`, env `PAX_SIDEKICK_WORKTREES`.
- **workmux already models a sub-agent count.** Its pi extension
  (`workmux/resources/pi/extensions/workmux-status.ts`) subscribes to a
  `suba:activity` event carrying `activeCount` and rolls it into the reported
  status. pax emits no such event and contains no reference to workmux.
- **workmux models the repo-root checkout as a first-class entry.**
  `workmux list --json` returns `{"handle":"dotfiles","is_main":true,"agent_statuses":[...]}`.
  `agent_statuses` is an array, so several agents under one entry is already
  representable.
- **`workmux send <NAME>` addresses a worktree**, supports `project:handle`
  cross-project syntax, and takes text or `--file`.
- **`mode: window` is workmux's default.** The current global config chose
  `mode: session` with `default_session: main`.
- **pi persists sessions by default** and `--session-id <id>` reuses an exact
  session, creating it if missing. A pax lead is therefore resurrectable, not
  precious.
- **`prefix+s` is `choose-tree -Zs`** — a tree of sessions with their windows
  nested, filterable, and a window can be selected directly from it. This is the
  primary navigation habit; `prefix+N` is not used.
- **pax's Computer view defaults to `computer.port: 0`** — a random free port per
  session. Env `PAX_COMPUTER_PORT`. `computer.autoOpen` defaults `false`.
- **`sidekick.maxParallel` defaults to 3** and is a budget shared across lanes.

## Design

### 1. Object model

| tmux object | Maps to | Lifetime |
|---|---|---|
| session | one repo | while the repo is active |
| window 0, `pax` | that repo's lead, at repo root | hours to days; resurrectable |
| windows 1..N | worktrees (`workmux add`) | per initiative, until merged |

There are 22 git checkouts under `~/src` at depth 1–2 (excluding `*__worktrees`),
with no basename collisions, so a session is named for the repo's basename.

Sessions are created on demand, so the session list holds only active repos.

### 2. Navigation

`prefix+s` serves both levels: collapsed it is the repo switcher, expanded it is
the per-repo task list, and a window can be selected directly across sessions.
No new navigation keybinding is required.

### 3. Configuration changes

- Flip global workmux config to `mode: window`. `workmux add` then creates a
  window in the current session, so running it from a repo's session places the
  worktree window beside that repo's pax. `default_session` becomes dead config.
- Each repo's window 0 runs pax with a stable `--session-id` derived from the repo
  name, so the window is cheap to kill and relaunch.
- Pin `PAX_COMPUTER_PORT` per repo so each repo has a stable Computer URL instead
  of a random one per launch. The port is derived deterministically from the repo
  name into a fixed high range, with collisions resolved by probing upward.

### 4. The front door

A new entry in the existing `prefix+w` `display-menu`, backed by a popup script in
`home/dot_config/tmux/workmux/`, matching the four scripts already there. It:

1. fzf-picks a repo from the checkouts under `~/src` (directories containing
   `.git`, excluding `*__worktrees`)
2. creates or attaches a tmux session named for the repo
3. starts window 0 as pax at the repo root with that repo's `--session-id` and
   pinned Computer port

### 5. The handoff

The central act of the new workflow, and the resolution to branch protection.

1. In the repo's session, `prefix+w → add w/prompt` creates a worktree window
   running Claude.
2. Claude plans, committing spec, plan, and
   `docs/superpowers/prompts/YYYY-MM-DD-<topic>-prompt.md` **on the planning
   branch**.
3. A new `prefix+w → dispatch` action runs `workmux send <repo> "<instruction>"`,
   where the instruction names the worktree's absolute path and the prompt file as
   an `@` reference, then switches to window 0. `workmux send` delivers text to the
   lead; the lead is what decides to call `delegate_to_sidekick` with that path as
   `workingDir`. The instruction has to be explicit enough that it reliably does so
   — making that reliable (wording, or a pax-side affordance) is an open
   implementation question, not a solved one.
4. pax's sidekick works **in that worktree, on that branch**, where the artifacts
   are already committed. Implementation commits land on top of the planning
   commits.
5. One push, one PR, containing spec, plan, prompt and implementation. Neither
   local nor protected main is ever merged into.

The planning worktree is not cleaned up at handoff — it is handed over. The agent
working in it changes from Claude to a pax sidekick; the worktree, the branch and
the tmux window persist as the unit of work.

This is what restores the dashboard: the unit of work is a workmux worktree again,
so `workmux list`, `prefix+s` and `workmux merge` all keep working on it.

### 6. Status bridge

The remaining gap: the sidekick process runs under the lead in window 0, so
nothing registers an agent in the worktree's own window and workmux shows the
worktree with blank status.

Two parts:

- **pax side** (PR to `persona-id/pax`): publish per-lane activity. pax knows each
  lane's cwd; workmux tracks worktrees by path; the join is the path. The existing
  `suba:activity` shape (`{ activeCount }`) is the minimum that makes the current
  workmux extension correct; a per-lane event carrying cwd is what makes the
  dashboard genuinely useful.
- **workmux side**: consume per-lane events and attribute status to the worktree
  matching each lane's cwd, rather than rolling everything onto the lead's entry.
  `agent_statuses` being an array means the data model already allows this.

Until the pax PR lands, the lead's entry reports `done` while sidekicks work. That
is the known-wrong state this bridge exists to fix, and it should not be worked
around with scraping.

## Precondition: prompts must be committable

The handoff works because the prompt is committed on the planning branch, which is
how the sidekick reads it from the worktree and how it reaches the PR. Any repo
that gitignores `docs/superpowers/` therefore cannot be dispatched from. This repo
ignored it until this change; other repos must be checked before first dispatch.

## Trade-offs accepted

- **Repos become sessions**, so the session list grows with active repos and
  `prefix+K` (kill-session) can take out a pax window. Mitigated by the stable
  `--session-id`: pax context lives in `~/.local/share/pi`, not the pane.
- **Shared-tree hazards.** With a lane pointed at a worktree of the same repo,
  `workspaceRev` hashes the whole tree, so unrelated edits can abort an in-flight
  testing-agent handoff; the Computer's Changes view is not lane-scoped. Both are
  documented in pax's README as open.
- **`sidekick.maxParallel` is a shared budget** (default 3), so concurrent
  initiatives queue rather than all running at once.
- **The design depends on a PR to a repo not solely owned here.** The status
  bridge is the only part that does; everything else works without it.

## Out of scope

- `sidekick.worktrees: false` (running lanes in the primary checkout) — noted as
  the other available posture, not chosen.
- Changing how pax itself plans or dispatches.
- Replacing `workmux dashboard` with a new surface.
