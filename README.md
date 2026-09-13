# dotfiles

[![CI](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml)

[![forthebadge](https://forthebadge.com/images/badges/0-percent-optimized.svg)](https://forthebadge.com)

My dotfiles. What else were you expecting?

## Use

On a fresh machine — one command, no prerequisites (chezmoi is a static binary
and ships its own git):

    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply \
      --source="$HOME/src/dotfiles" ianchesal/dotfiles

It prompts for `sudo` partway through (adding zsh to `/etc/shells` and `chsh`),
so it is not unattended.

Day to day:

    dfu                 # pull, preview the diff, confirm, apply, then update everything
    chezmoi diff        # what would change?
    chezmoi apply       # deploy
    rake -T             # the update fan-out (Rake no longer deploys anything)

**Switching a machine that still uses the old rake/symlink setup?** Do not just
`git pull` — see `MIGRATION.md` on the `main` branch. A plain pull removes the
tracked files out from under the live symlinks and leaves you with a bare shell.

See `docs/chezmoi-workflows.md` for adding and removing tools, changing
settings, and the gotchas.
