# Migrating this machine to chezmoi

Deployment is moving from the hand-rolled Rake/symlink system to
[chezmoi](https://www.chezmoi.io). This is the runbook for switching one
machine over. It takes about ten minutes.

**Read the warning below before you run anything.**

## Do not just `git pull` the chezmoi branch

On the chezmoi branch the managed config directories no longer live at the repo
root — they move into `home/` as chezmoi source state. If you check that branch
out while your symlinks are still live, git removes every **tracked** file
inside `zsh/`, `claude/`, `git/` and the rest, while leaving untracked runtime
state behind.

Your symlinks then point at near-empty directories. `~/.config/zsh` loses
`.zshrc`. `~/.zshenv` — which sets `ZDOTDIR` — becomes a dangling symlink.
**Your next login shell is bare, and Claude Code loses its memory and skills.**

Nothing is destroyed (untracked state survives, and you take a backup anyway),
but you do not want to discover this halfway through a workday.

`script/chezmoi-prep` exists to convert everything into real files and
directories *first*, so the branch switch is a no-op for those paths.

## Before you start

- Do this on a machine where a broken shell costs you nothing.
- You will need `sudo` only if chezmoi isn't installed and Homebrew has to
  install it.
- `nvim` is deliberately left as a symlink into the repo on both branches. If a
  step seems to skip it, that is correct.

## The procedure

### 1. Get the prep script

```bash
cd ~/src/dotfiles
git checkout main
git pull
```

You are still on `main`. Nothing has changed yet.

### 2. See what prep would do

```bash
./script/chezmoi-prep --dry-run
```

Read it. Every action is a `rm` of a symlink followed by a `mv` of the
directory it pointed at. Nothing is copied over anything, and nothing is
deleted recursively.

### 3. Run prep

```bash
./script/chezmoi-prep
```

It will:

1. **Back up** everything behind the symlinks to
   `~/dotfiles-pre-chezmoi-<date>.tgz`, dereferencing them — and verify the
   dereference actually happened rather than trusting the flag.
2. **Convert the loose file symlinks** (`.zshenv` first, deliberately) into
   real files.
3. **Convert the directory symlinks** into real directories, carrying untracked
   state across: Claude sessions and credentials, `gh` OAuth tokens, tmux
   plugins, zsh compdump.
4. **Verify** nothing still points into the repo, nothing dangles, and
   `~/.config/nvim` is untouched.

It is idempotent — anything already converted is skipped — and it aborts rather
than continuing if a check fails.

**Your machine still works on `main` at this point.** You can stop here
indefinitely. Open a new shell and confirm things are normal if you like.

### 4. Switch branches

```bash
git checkout explore-not-using-rake-here
```

This is clean: the directories prep moved out are the same ones the branch
deletes, so git has nothing to overwrite.

### 5. See what the migration would do

```bash
./script/chezmoi-migrate --dry-run
```

This refuses to proceed unless prep has run, prints the full `chezmoi diff`,
and applies nothing.

### 6. Run the migration

```bash
./script/chezmoi-migrate
```

It installs chezmoi if needed, points it at this checkout, shows you the diff,
**waits for you to confirm**, applies, and then verifies.

The confirmation matters. On a machine chezmoi has never written to, it has no
record of what it previously deployed, so `apply` treats every existing file as
unmanaged and replaces it **without prompting**. The diff is your only preview.

### 7. Check it

```bash
exec zsh              # new shell
gh auth status        # tokens survived
du -sh ~/.claude      # sessions survived
rake nvim:outdated    # nvim machinery intact
chezmoi status        # empty
```

## If something goes wrong

Your backup is at `~/dotfiles-pre-chezmoi-<date>.tgz`, taken with symlinks
dereferenced, so it holds real content.

```bash
cd ~ && tar xzf ~/dotfiles-pre-chezmoi-<date>.tgz
```

To go back to the old world entirely:

```bash
cd ~/src/dotfiles && git checkout main
rm -rf ~/.config/zsh ~/.claude   # ...and any other path you want re-linked
rake all
```

Keep the backup until at least one other machine has migrated successfully.

## What changes afterwards

| | Before | After |
| --- | --- | --- |
| Deploy | edit repo; symlink makes it live instantly | `chezmoi apply` (nvim still instant) |
| Daily update | `dfu` — stash, pull, run, unstash | `dfu` — pull, **diff, confirm**, apply, update |
| New machine | clone, bootstrap Ruby, `rake all` | one `chezmoi init --apply` line |
| Add a tool | write a `.rake` file | `chezmoi add <path>` |
| Remove a tool | edit rake, rm symlinks by hand | `chezmoi forget` / `chezmoi destroy` |

Full detail: `docs/chezmoi-workflows.md` on the chezmoi branch.

## Why bother

The symlink model made the repo working tree *be* the live config directory, so
every tool wrote its state into git. That cost:

- **330 MB** in a repo whose actual config payload is 2.7 MB
- **68 of 83** `.gitignore` rules existing only to hold back tool state — a
  blocklist maintained reactively, one commit every ten days
- `~/.claude/.credentials.json` and `~/.config/gh/hosts.yml` sitting **inside
  the git worktree**, held out of a commit by a `.gitignore` line
- a `dfu` that had to blind-stash the worktree before it could pull, with an
  `&&` chain that silently swallowed your work whenever an update step failed

After the migration the repo is a source, the state has nowhere to flow back
to, and `.gitignore` is 15 lines.
