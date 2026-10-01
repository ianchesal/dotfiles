# pax workflow

How design, dispatch and implementation fit together now that pax is in the
picture. Companion to `docs/chezmoi-workflows.md`; the design of record is
`docs/superpowers/specs/2026-09-21-pax-tmux-workflow-design.md`.

## Mental model

**One pax lead per machine. A repo is a plain tmux session. Worktrees are its
windows.**

```
session: pax           <- the lead. one pane: pi in ~/src. runs for days.
  window 1  pax

session: web           <- the persona-web checkout
  window 1  zsh        <- a bare shell at the repo root
  window 2  add-sso    <- a worktree. Claude plans here, then pax implements here.
  window 3  fix-1234   <- another worktree.
                          (pax's own sidekick worktrees are invisible - its business)

session: dotfiles
  window 1  zsh
  ...
```

Repo sessions are named for the repo with any `persona-` prefix stripped,
matching how `window-name.sh` labels windows — nearly every work repo is
`persona-*`, so the prefix is noise in the session list. The one exception is
`persona-pax`, which keeps its full name so it never collides with the lead.

Two agents, two jobs:

- **Claude** does design and planning. It is good at it; pax is not.
- **pax** is a technical PM and dispatcher. It wants to run constantly, be fed
  work, and decide where and how it happens. It owns its own sub-agents.

The handoff between them is the whole point of this workflow.

### Why one lead, not one per repo

Until October 2026 every repo session carried its own lead (`pi --session-id
pax-<repo>`) and its own Computer port from a registry. That meant ~20 idle
dispatchers, a port registry to keep collision-free, and opening a repo always
cost a pi start. One lead in `~/src` sees every repo on the machine, and pax is
happy with it: `resolveLaneCwd` (`pax/src/sidekick/lane-cwd.ts`) only refuses a
`workingDir` that is a subdirectory of the lead's own repo, and `~/src` is not a
repo, so every checkout and worktree is a valid target. The rest of pax degrades
cleanly outside a git repo (`workspaceRev` reports `{head: "", dirty: ""}`).

### Navigation

`prefix+s` (`choose-tree -Zs`) is the only navigation you need. Collapsed it is
the repo list plus `pax`; expanded it is every worktree for that repo, and a
window can be selected directly across sessions.

---

## The loop

### 0. Start the lead — `prefix+w` → `pax lead` (`P`)

Once per boot, or whenever pi has exited. Creates session `pax` with one window,
also `pax`, running in `~/src`:

```
PAX_COMPUTER_PORT=8800 pi --session-id pax
```

If it is already running, this just switches you to it. The `--session-id` is
what makes the lead **cheap to kill and relaunch** — the multi-day context lives
in pi's session store, not in the pane. pi is the session's only process, so
quitting it ends the session; `P` again picks up where it left off. The Computer
is always on port 8800, so `http://localhost:8800` is worth bookmarking.

### 1. Open a repo — `prefix+w` → `open repo` (`R`)

fzf-picks a checkout under `~/src` and creates a session for it with one bare
shell at the repo root. No pi, no split. Re-running it switches to the existing
session instead of recreating it.

### 2. Start an initiative — `prefix+w` → `add w/prompt` (`p`)

From inside the repo's session. Because workmux is in `mode: window`, this
creates a **window next to pax**, not a separate session.

Claude works there: brainstorm → spec → plan → prompt. All three land on that
branch, committed:

```
docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md
docs/superpowers/plans/YYYY-MM-DD-<topic>.md
docs/superpowers/prompts/YYYY-MM-DD-<topic>-prompt.md
```

`docs/superpowers/` is **committed, not ignored**. The prompt has to reach the
branch for pax to read it, and has to reach the PR to be reviewable. A repo that
gitignores that path cannot be dispatched from — `pax-dispatch.sh` detects this
and says so rather than reporting a missing prompt.

TODO: Do we need to clean up `docs/superpowers/**` at some point? These are
eventually out of date artifacts that clutter up the repo.

### 3. Hand off — `prefix+w` → `dispatch to pax` (`D`)

Run from the worktree window, in any repo session. It:

1. finds the prompt the branch added (`git diff --name-only <base>...HEAD`)
2. pastes the lead an instruction naming the worktree as `workingDir`, with the
   prompt as an **absolute** `@` path
3. switches you to the `pax` session

If the lead is not running it fails with a pointer to `P` rather than starting
one: pasting into a pi that is still booting can lose the text silently.

Delivery is tmux, not `workmux send` — the lead is not a workmux agent, because
`~/src` is not a worktree. The instruction goes through a named buffer
(`pax-dispatch`, so your own paste buffer is untouched), is bracketed-pasted into
`=pax:pax`, and is submitted with Enter: the same sequence `workmux send` uses.

### 4. pax implements — in that same worktree, on that same branch

Implementation commits land on top of the planning commits. Spec, plan, prompt
and code reach review as **one PR**.

### 5. Land it — `workmux merge`

Cleans up the worktree and its window.

---

## Why the handoff works this way

This is the non-obvious part, and the reason not to "simplify" it later.

**pax baselines off `origin/main`, never local main.** `baselineFor`
(`pax/src/sidekick/lane-worktrees.ts:150`) does `git fetch origin` →
`origin/HEAD` → `origin/main` → `HEAD`. Two consequences:

1. Merging a planning branch into **local main is invisible to pax**. It would
   branch from `origin/main` and never see your spec.
2. Leaving artifacts **uncommitted in the repo root is also invisible**. A
   `git worktree add` from `origin/main` produces a clean tree; only configured
   `copyDependencies` globs cross over, and those are for `node_modules`-shaped
   files.

Combined with protected upstream branches — you usually cannot push a local main
merge anyway — there is no route that puts the spec where pax would find it.

**So we hand pax the worktree instead.** `resolveLaneCwd`
(`pax/src/sidekick/lane-cwd.ts`) explicitly accepts a worktree of the same repo
and resolves the lane to that worktree's own root. No worktree is provisioned,
`origin/main` never enters it, and the artifacts are already committed there.

**Name `workingDir` explicitly, always.** `sidekick.worktrees` defaults to
`true`, so a delegation *without* one makes pax provision its own worktree off
`origin/main` — outside workmux's view, invisible to the dashboard, on a
`pax/...` branch you did not ask for. The instruction wording is the only thing
steering it away.

**The `@` path must be absolute.** The lead's cwd is `~/src`, where a
worktree-relative path silently resolves to nothing.

---

## Observability — do not trust green

**`workmux list` and the dashboard report `done` while pax is still working.**

pax deliberately defers work to background sidekicks so the lead chat stays
responsive. The lead therefore settles almost immediately, and workmux's pi
extension — which reports from `agent_start`/`agent_settled` — calls it done
while three sidekicks grind away.

`/pax-computer` is the honest surface until this is fixed: **Progress**,
**Changes**, **Shell**, **Computer**, **Tasks**.

The fix is pax-side and needs no workmux change, because both seams already
exist upstream:

- workmux's bundled pi extension already subscribes to a `suba:activity` event
  carrying `activeCount`. pax emitting it is sufficient to correct the lead's
  status.
- `set-window-status` and `register-agent` resolve their target pane from
  `$TMUX_PANE`, so a lane can mark the worktree window it is working in.

Do **not** work around this by scraping pax's Computer server.

---

## Command reference

| Action | How |
|---|---|
| Start or switch to the pax lead | `prefix+w` → `pax lead` (`P`) |
| Open a repo as a session | `prefix+w` → `open repo` (`R`) |
| New worktree + Claude, with a prompt | `prefix+w` → `add w/prompt` (`p`) |
| New worktree from an existing branch | `prefix+w` → `add w/branch` (`b`) |
| Hand the worktree to pax | `prefix+w` → `dispatch to pax` (`D`) |
| Navigate repos and worktrees | `prefix+s` |
| Agent status across the machine | `prefix+w` → `dashboard` (`d`) — *see caveat above* |
| pax's real activity | `/pax-computer` in the lead |
| Land the work | `workmux merge` |
| Preview a dispatch without sending | `PAX_DISPATCH_DRY_RUN=1 ~/.config/tmux/workmux/pax-dispatch.sh` |

---

## Gotchas

**`prefix+K` on the `pax` session kills the lead.** Less alarming than it
sounds: `--session-id` means the context survives. `prefix+w` → `P` and pax
continues. Killing a repo session no longer touches pax at all.

**Leftovers from the per-repo layout.** Old `pax-<repo>` pi sessions stay in
pi's session store and the port registry at
`${XDG_STATE_HOME:-~/.local/state}/pax/ports` stays on disk; nothing reads
either any more. Any repo session opened before the switch still has its split
pane with a per-repo pi in it until you kill it.

**Flipping to `mode: window` did not convert existing session-mode worktrees.**
They still work; they are just sessions. New ones are windows.

**Editing these scripts is not live until `chezmoi apply`.** They are copied,
like everything except `nvim/`.

**From a worktree, `chezmoi` reads main's source state unless you pass
`--source`.** This is the trap that bit during the first dispatch — the diff
reads *backwards*, so chezmoi proposing to revert your change looks identical to
your change being applied. See the chezmoi section of `AGENTS.md`.

**`sidekick.maxParallel` defaults to 3** and is a budget shared across lanes —
now across every repo on the machine, since there is one lead — so concurrent
initiatives queue rather than all running at once.

**Shared-tree hazards.** With a lane pointed at a worktree of the same repo,
pax's `workspaceRev` hashes the whole tree, so an unrelated edit can abort an
in-flight testing-agent handoff; the Computer's Changes view is not lane-scoped.
Both are documented as open in pax's README.

**The plan document lives in the worktree the agent owns.** Correcting a plan
mid-run means steering the lead, not editing the file — the lead has already read
it, and two writers in one tree is exactly what this design avoids.
