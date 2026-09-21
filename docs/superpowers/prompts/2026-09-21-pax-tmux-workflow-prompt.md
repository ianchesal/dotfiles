# Task: build the dotfiles side of the pax dispatcher tmux workflow

You are working in `dotfiles` (chezmoi source state, bash + just + tmux, deployed to
macOS, Debian Linux and WSL2). Read `AGENTS.md` before anything else — the chezmoi
layout section is load-bearing and the naming rules there are not negotiable. Then read,
in order:

- `docs/superpowers/specs/2026-09-21-pax-tmux-workflow-design.md` — the design of record
- `docs/superpowers/plans/2026-09-21-pax-tmux-workflow-dotfiles.md` — **the plan is the
  contract.** It contains every file, every test and every command, task by task.

The plan already did the brainstorm-and-plan work. Do not re-plan it. Execute it
task-by-task, in order, committing at the end of each task as its final step says.

---

## 1. The problem

The current workflow is one `main` tmux session with a shell pane at each repo root, and
`workmux` creating a session per worktree running Claude. pax breaks it: pax is a
long-running **per-repo** dispatcher that owns its own sub-agents, so a per-worktree pax
is the wrong granularity, and the unit of work stops being a tmux object.

This task rebuilds the tmux layer around that: a session per repo with pax in window 0,
worktrees as windows inside it, and a dispatch action that hands a Claude planning
worktree to the repo's lead.

## 2. What already exists — reuse it, do not rebuild it

| Thing | Where | Use it for |
|---|---|---|
| tmux popup script pattern | `home/dot_config/tmux/workmux/*.sh` | The four existing scripts are the house style for a popup helper, including the `FZF_DEFAULT_OPTS` `--tmux` stripping comment. Copy that comment verbatim where it applies. |
| The `prefix+w` menu | `home/dot_config/tmux/tmux.conf:147` | `display-menu` block you are adding two entries to. |
| Test harness idiom | `script/tests/brew-trust.test.sh` | `here`/`subject`, `mktemp -d` + EXIT trap, fake binaries by env seam, `check label expected actual`, `failures` counter, nonzero exit. Match it exactly. |
| Env-seam documentation style | `script/brew-trust` header | Every script documents its seams in a header comment block. Match the density and the tone. |
| workmux config | `home/dot_config/workmux/config.yaml` | Task 1 rewrites it. |

## 3. Decisions already made — do not reopen these

Settled with Ian before this handoff. Implement them; do not relitigate them in a plan
of your own.

1. **Session per repo, pax in window 0 named `pax`.** Not a window per repo in one
   session. Navigation is `prefix+s` (`choose-tree`), which shows sessions with their
   windows nested — that is the whole reason this topology won.
2. **workmux is NOT modified.** It is upstream `raine/workmux` installed via Homebrew,
   not an owned tool. If you find yourself wanting to patch it, you have taken a wrong
   turn — use its existing seams (`$TMUX_PANE`, `workmux send`, `workmux list --json`).
3. **pax is NOT modified in this task.** The status bridge is a separate plan in a
   separate repo.
4. **Ports come from a persisted registry, not a hash of the repo name.** Hashing ~22
   repos into any memorable range collides far more often than intuition suggests. The
   registry cannot collide. Do not "simplify" this back to a hash.
5. **The dispatch instruction names `workingDir` explicitly.** A delegation without one
   makes pax provision a worktree off `origin/main` that workmux cannot see. This is the
   single most important line in the script.
6. **The `@` prompt path is absolute.** The lead's cwd is the repo root on `main`, where
   a prompt committed on a planning branch does not exist. A worktree-relative path
   silently resolves to nothing.

## 4. The part that is easy to get wrong

**You are modifying the tmux configuration you are running inside.**

- Task 1 flips workmux from `mode: session` to `mode: window` **globally**. Existing
  session-mode worktrees — including, possibly, the one you are working in — are not
  retroactively converted. That is expected. Do not try to migrate them.
- Task 4's verification runs `tmux source-file ~/.config/tmux/tmux.conf` against the live
  server. That is intentional and safe, but it means a malformed menu line fails loudly
  in the session you are using. That is the point of the step.
- `chezmoi apply` is what makes any of this live. A tmux or workmux config edit in the
  source state does nothing until applied. **`nvim/` is the only `symlink_` entry in this
  repo** — everything else is copied.
- Do not `chezmoi re-add` anything. Do not touch `~/.claude/settings.json`.

**The interactive-read trap.** The existing popup scripts end a failure path with
`read -n 1 -s` so the message stays on screen. Under a test harness that hangs forever.
The plan guards it with `[ -t 0 ]`. Keep that guard.

## 5. Tests

TDD, and the plan gives you the test file contents verbatim — write the test, watch it
fail, then write the script. Do not write the script first and backfill a test.

- `script/tests/pax-open-repo.test.sh` drives the opener against a fake `tmux` and a
  scratch `~/src`.
- `script/tests/pax-dispatch.test.sh` builds a **real** git repo with **real** worktrees
  in a scratch dir, because prompt discovery is git plumbing and faking git would test
  nothing. Only `workmux` and `tmux` are faked.

Both must be executable (`chmod +x`) or `just test-scripts` silently skips them.

## 6. Out of scope

- The pax status bridge (`suba:activity`, `$TMUX_PANE`-targeted status). Separate plan,
  separate repo. **Do not work around the missing status by scraping pax's Computer
  server** — that is explicitly rejected in the spec.
- Any change to `raine/workmux` or `persona-id/pax`.
- Migrating existing session-mode worktrees.
- `nvim/`, `brew/`, `asdf/`, or anything else the plan does not name.
- Adding a markdown linter. This repo deliberately has none.

## 7. Definition of done

- `just lint` passes — shellcheck `--severity=warning` on every new script **and test**,
  plus `just --fmt --check`. Do not report done on a subset.
- `just test-scripts` passes, with `pax-open-repo` and `pax-dispatch` both appearing and
  every pre-existing test still green.
- Every new deployed script carries the `executable_` prefix in the source state and a
  header comment documenting its env seams.
- `chezmoi diff` shows only the paths the plan names.
- Four commits, one per task, each with the message the plan specifies.
- The manual-verification checklist at the end of the plan is left for Ian. Do not
  attempt it — it needs a live tmux and a live pax, and running it would disturb the
  session you are in.

## 8. Working agreement

You are on branch `pax-tmux-workflow-design`, in a worktree. **All commits land on that
branch, in that worktree.** Do not create a new branch and do not touch `main` — this
repo's main is protected upstream, and the whole point of the design is that spec, plan,
prompt and implementation reach review as one PR.

Commit subjects: imperative mood, no Conventional Commit prefix — match what is already
in `git log`.

**Stop and ask** rather than guessing if: a test in the plan does not fail the way the
plan says it will, `shellcheck` objects to something the plan told you to write, or the
bash-3.2 constraint makes a step in the plan impossible as written. Those are signals the
plan is wrong, and a wrong plan should be corrected, not worked around silently.
