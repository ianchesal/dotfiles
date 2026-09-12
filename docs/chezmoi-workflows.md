# chezmoi workflows

> **STATUS: not yet in effect.** This describes how the repo works *after* the
> chezmoi migration. Until that lands, deployment is still `rake all` and the
> symlink model. See `docs/superpowers/specs/2026-09-11-chezmoi-migration-design.md`
> for the design and the migration plan beside it.

## Mental model

The repo is a **source**, not the live config directory.

```
~/src/dotfiles/              the source (git)
  .chezmoiroot               -> "home"
  home/                      chezmoi source state
    dot_config/tmux/...      -> deployed as ~/.config/tmux/...
    dot_claude/...           -> deployed as ~/.claude/...
  nvim/                      OUTSIDE the source state - symlinked, not copied
  brew/ script/ docs/        never deployed
  Rakefile, */*.rake         the update fan-out only
```

Configs are **copied** into place, not symlinked. Two consequences worth
internalising:

1. **Tools write their state to the real directory, not into your git worktree.**
   `~/.claude/projects/` no longer lands in the repo. This is why `.gitignore`
   shrank from 83 rules to ~15, and why OAuth credentials are no longer sitting
   in the working tree behind a `.gitignore` line.
2. **Editing a source file is not instantly live.** It needs `chezmoi apply`.
   The one exception is `nvim/`, which is deliberately symlinked — see below.

### The nvim exception

`~/.config/nvim` is a symlink to `<repo>/nvim`, placed by a single `symlink_`
entry. Everything under it is invisible to chezmoi (`status`, `diff`, `verify`
all ignore it).

This is not convenience, it is structural. `nvim/scripts/update.lua:20` resolves
`config_dir` **script-relative** and writes `pins.json` there, while `vim.pack`
writes `nvim-pack-lock.json` against the *config* dir. Under copy mode those
two paths diverge, breaking the invariant `rake nvim:commit` enforces — that
both files agree and travel in one commit. Symlinking keeps them co-located.

The side benefit: editing a plugin spec is still instantly live, on the
directory that sees ~5x more commits than any other.

---

## Daily update — `dfu`

```zsh
chezmoi git pull -- --autostash --rebase
chezmoi diff                                  # preview
read -q "Apply these changes? [y/N] "         # gate
chezmoi apply --error-on-conflict
rake update && zinit update
rake nvim:commit                              # if pins moved
```

You get a preview and an explicit gate. Under the old symlink model `git pull`
*was* deployment — a pulled change was live in every running process before you
could look at it.

The old blind `git stash push -u` is gone. It existed only because the worktree
was chronically dirty with tool-written state, and it carried a real bug: an
`&&` chain meant any failure between stash and pop left your work silently
stashed.

Two guards are retained from the original function and must not be dropped:

- refuse to run if `nvim/pins.json` or `nvim/nvim-pack-lock.json` have
  uncommitted or staged changes
- `rake nvim:commit` afterwards if the updater moved the pins

`zinit update` also stays. The tpm external keeps *tpm itself* current but never
touches the plugins tpm manages; the same is true of zinit and its plugins.

---

## Switching an existing machine over

A machine that is still on the rake/symlink model must **not** simply
`git pull` the migrated repo. The migration commits delete `zsh/`, `claude/`
and friends from the repo; a pull removes every tracked file inside them while
leaving untracked state behind, which leaves `~/.config/zsh` pointing at an
almost-empty directory and `~/.zshenv` — which sets `ZDOTDIR` — dangling. The
next login shell is bare.

The order that works: back up, de-symlink the loose files, cut over the
directories, *then* take the new tree, then init and apply. The full procedure
with the exact commands is in the migration plan's **Per-machine rollout**
section (`docs/superpowers/plans/2026-09-11-chezmoi-migration.md`).

Once a machine is switched over, `dfu` is the only thing it needs.

---

## Bootstrapping a new machine

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply \
  --source="$HOME/src/dotfiles" ianchesal/dotfiles
```

chezmoi is a single static binary with a builtin git, so a bare machine needs
neither git nor a language runtime. It clones, runs the `run_once_` scripts
(Homebrew → Brewfile → `/etc/shells` → `chsh` → asdf+Ruby → terminfo → gh
extensions → rustup), then applies every config.

Two things to know:

- **It is not unattended.** `/etc/shells` and `chsh` need `sudo`, so it prompts
  partway through.
- **`--source` is deliberate.** chezmoi defaults to `~/.local/share/chezmoi`.
  Pinning it to `~/src/dotfiles` keeps the repo where the git worktree workflow
  expects it, and is where `~/.config/nvim` will point.

This replaces `bootstrap/cloud-workstation.sh`, which had to install Homebrew,
then asdf, then Ruby 3.3.9, before `rake zsh` could create a single symlink.

---

## Adding a tool

```bash
chezmoi add ~/.config/newtool
chezmoi cd && git add -A && git commit -m "add newtool" && git push
```

`chezmoi add` applies `dot_` prefixes automatically at every level
(`.hidden-rc` → `dot_hidden-rc`), so source files are never hand-named.

No `.rake` file, no `dolink`, no `task all:` / `task clean:` wiring. Other
machines pick it up on their next `dfu`.

If the tool also needs a package installed, add it to `brew/Brewfile` — the
`run_once_before_20-brew-bundle` script handles it on new machines.

---

## Removing a tool

```bash
chezmoi forget ~/.config/oldtool     # stop managing; leave the files on disk
chezmoi destroy ~/.config/oldtool    # remove from source AND from disk
chezmoi cd && git add -A && git commit
```

Two caveats:

- **Deletion does not propagate.** Removing an entry from the source leaves the
  target orphaned on your *other* machines — it simply becomes unmanaged there.
  To actually remove it everywhere, add the path to `.chezmoiremove`. (The old
  `rake clean` didn't propagate either, so this is not a regression, but it is
  not automatic.)
- **Tool state directories are outside chezmoi's knowledge.**
  `~/.local/share/nvim`, `~/.cache/*` and friends still need explicit cleanup.

---

## Changing a tool's settings

Two workflows. The second is new and has no equivalent under symlinks.

**(a) Edit the source, then deploy:**

```bash
chezmoi edit ~/.config/tmux/tmux.conf --apply
```

**(b) Experiment on the live file, capture when happy:**

```bash
vim ~/.config/tmux/tmux.conf                # hack on the deployed file
chezmoi diff                                 # see exactly what drifted
chezmoi re-add ~/.config/tmux/tmux.conf      # pull it back into the source
```

Under the symlink model, hacking on a live config *was* editing the git
worktree — there was no "try it, then decide." Copy mode gives a real staging
boundary.

`chezmoi status` uses two columns: the first is drift since chezmoi last wrote
the file, the second is what `apply` would change.

---

## Working on nvim

Unchanged from before the migration:

```bash
rake nvim:update      # 30-day delayed pin updates, then mason prune
rake nvim:outdated    # preview eligible updates
rake nvim:commit      # commit pins.json + lockfile together
```

Editing `nvim/lua/plugins/*.lua` is live immediately — no `apply`. See
[the nvim exception](#the-nvim-exception) for why.

---

## Command reference

| Task | Command |
| --- | --- |
| What would change? | `chezmoi diff` |
| What has drifted? | `chezmoi status` |
| Deploy | `chezmoi apply --error-on-conflict` |
| Deploy one path | `chezmoi apply --error-on-conflict ~/.config/tmux` |
| Pull + deploy | `chezmoi update` (no gate — prefer the `dfu` flow) |
| Go to the source repo | `chezmoi cd` |
| Where is the source? | `chezmoi source-path` |
| What does chezmoi own? | `chezmoi managed` |
| Start managing a file | `chezmoi add <path>` |
| Capture a live edit | `chezmoi re-add <path>` |
| Edit source + deploy | `chezmoi edit <path> --apply` |
| Stop managing | `chezmoi forget <path>` |
| Remove everywhere | `chezmoi destroy <path>` |
| Resolve drift interactively | `chezmoi merge-all` |

---

## Gotchas

- **`.chezmoi.workingTree` is the repo root; `.chezmoi.sourceDir` is
  `<repo>/home`.** Under `.chezmoiroot`, templates that need the repo (the nvim
  symlink, the Brewfile path) must use `workingTree`.
- **Drift protection is machine-local.** `chezmoistate.boltdb` lives beside the
  config, not in the repo. On a machine chezmoi has not written to before,
  every existing file counts as pre-existing and unmanaged, and `apply` will
  **not** prompt. `chezmoi diff` first is the only safeguard.
- **chezmoi never backs up what it replaces.** There is no `.bak`, no restore
  command. `purge` removes chezmoi's own state and leaves your dotfiles in
  place; `destroy` deletes both sides.
- **`create_` means seed once, never touch again.** That is what protects an
  existing `~/.claude/settings.json` — including work-specific keys on a work
  machine — from being overwritten by the skeleton.
- **`~/.work_machine` stays a runtime check.** `git/gh-dash/gh-dash.sh` reads
  the file itself rather than being templated at apply time, so tmux popups and
  cron agree with interactive shells. Both `config.yml` and `config-work.yml`
  deploy everywhere.
- **Every config deploys on every platform.** No OS gating: a kitty config on a
  Linux box is inert, and not worth a template guard to suppress.
- **`~/.claude.json` is a sibling of `~/.claude`**, outside chezmoi's target
  set. Its 0600 chmod is handled by `run_once_after_70-chmod-claude-json.sh`.
- **`script/cutover` is migration-only.** Once a directory is a real directory,
  the script refuses to run against it again.
