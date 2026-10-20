# pax workflow

How design, dispatch and implementation fit together now that pax is in the
picture. Companion to `docs/chezmoi-workflows.md`; the design of record is
`docs/superpowers/specs/2026-09-21-pax-tmux-workflow-design.md`.

> **October 2026:** pax is out of use, so `open repo` no longer launches it — a
> session opens with just the `shell` window — and `dispatch to pax` is gone
> from the `prefix+w` menu. The rest of this doc describes the loop as it ran
> with pax; to run it again, start pi by hand in a window named `pax` (see step
> 1) and run `~/.config/tmux/workmux/pax-dispatch.sh` directly (see step 3).

## Mental model

**A repo is a tmux session. A shell is the first window, then pax if you start
it. Worktrees are the others.**

The session is named for the repo with any `persona-` prefix stripped, matching
how `window-name.sh` labels windows — nearly every work repo is `persona-*`, so
the prefix is noise in the session list.

```
session: web           <- the persona-web checkout
  window 1  shell      <- a bare prompt at the repo root.
  window 2  pax        <- the lead: pi, full window. runs for hours to days.
  window 3  add-sso    <- a worktree. Claude plans here, then pax implements here.
  window 4  fix-1234   <- another worktree.
                          (pax's own sidekick worktrees are invisible - its business)

session: dotfiles
  window 1  shell
  window 2  pax
  ...
```

Indices start at 1 (`base-index`) and `renumber-windows` closes gaps, so the pax
window's number is not stable. Target it by name (`:pax`) rather than by number.

Two agents, two jobs:

- **Claude** does design and planning. It is good at it; pax is not.
- **pax** is a technical PM and dispatcher. It wants to run constantly, be fed
  work, and decide where and how it happens. It owns its own sub-agents.

The handoff between them is the whole point of this workflow.

### Navigation

`prefix+s` (`choose-tree -Zs`) is the only navigation you need. Collapsed it is
the repo list; expanded it is `shell`, `pax` and every worktree for that repo, and a
window can be selected directly across sessions. One keystroke covers both
levels, which is why repos are sessions rather than windows in one big session.

---

## The loop

### 1. Open a repo — `prefix+w` → `open repo` (`R`)

fzf-picks a checkout under `~/src`, creates a session named for the repo with
`persona-` stripped, and opens one window at the repo root: `shell`, a bare
prompt. Re-running it focuses the existing session instead of recreating it.

It used to open pax in a second window too. To bring the lead up by hand, run
this from the shell window (the window must be named `pax`, because dispatch
targets `:pax`):

```
tmux new-window -a -n pax 'pi --session-id pax-<repo>'
```

Use the full basename, including any `persona-` prefix, for `<repo>`. The
`--session-id` is what makes the lead **cheap to kill and relaunch**: the
multi-day context lives in pi's session store, not in the window.

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

### 3. Hand off — `~/.config/tmux/workmux/pax-dispatch.sh`

Run from the worktree window. It:

1. finds the prompt the branch added (`git diff --name-only <base>...HEAD`)
2. sends the lead an instruction naming the worktree as `workingDir`, with the
   prompt as an **absolute** `@` path
3. switches you to the `pax` window

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

**The `@` path must be absolute.** The lead's cwd is the repo root on `main`,
where a prompt committed on a planning branch does not exist. A worktree-relative
path silently resolves to nothing.

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
| Open a repo as a session | `prefix+w` → `open repo` (`R`) |
| New worktree + Claude, with a prompt | `prefix+w` → `add w/prompt` (`p`) |
| New worktree from an existing branch | `prefix+w` → `add w/branch` (`b`) |
| Hand the worktree to pax | `~/.config/tmux/workmux/pax-dispatch.sh` (no longer in the `prefix+w` menu) |
| Navigate repos and worktrees | `prefix+s` |
| Agent status across the machine | `prefix+w` → `dashboard` (`d`) — *see caveat above* |
| pax's real activity | `/pax-computer` in the lead |
| Land the work | `workmux merge` |
| Preview a dispatch without sending | `PAX_DISPATCH_DRY_RUN=1 ~/.config/tmux/workmux/pax-dispatch.sh` |

---

## Gotchas

**`prefix+K` kills a session, and a repo session contains pax.** Less alarming
than it sounds: `--session-id` means the context survives. Reopen the repo and
pax continues.

**Flipping to `mode: window` did not convert existing session-mode worktrees.**
They still work; they are just sessions. New ones are windows.

**Editing these scripts is not live until `chezmoi apply`.** They are copied,
like everything except `nvim/`.

**From a worktree, `chezmoi` reads main's source state unless you pass
`--source`.** This is the trap that bit during the first dispatch — the diff
reads *backwards*, so chezmoi proposing to revert your change looks identical to
your change being applied. See the chezmoi section of `AGENTS.md`.

**`sidekick.maxParallel` defaults to 3** and is a budget shared across lanes, so
concurrent initiatives queue rather than all running at once.

**Shared-tree hazards.** With a lane pointed at a worktree of the same repo,
pax's `workspaceRev` hashes the whole tree, so an unrelated edit can abort an
in-flight testing-agent handoff; the Computer's Changes view is not lane-scoped.
Both are documented as open in pax's README.

**The plan document lives in the worktree the agent owns.** Correcting a plan
mid-run means steering the lead, not editing the file — the lead has already read
it, and two writers in one tree is exactly what this design avoids.
