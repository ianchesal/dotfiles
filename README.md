# dotfiles

[![CI](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml)

[![forthebadge](https://forthebadge.com/images/badges/0-percent-optimized.svg)](https://forthebadge.com)

My dotfiles. What else were you expecting?

## Use

On a fresh machine — one command (chezmoi is a static binary and ships its own
git, so it has no prerequisites beyond `curl` and `git` for Homebrew):

    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply \
      --source="$HOME/src/dotfiles" ianchesal/dotfiles

That clones the repo, installs Homebrew and every package in `brew/Brewfile`
(via `home/run_once_before_20-brew-bundle.sh`), deploys the configs, then runs
the `run_once_after` scripts. It prompts for `sudo` during the Homebrew install,
so it is not unattended.

Two steps are deliberately left out of `chezmoi apply` and are yours to run:

    just shell::set-default   # register Homebrew zsh in /etc/shells and chsh
    just install-runtimes     # Rust toolchain, then the asdf runtimes

`chsh` is the one step that can lock you out of a machine, so it stays an
explicit act rather than a side effect. Then check the result:

    just doctor         # is this box actually provisioned?

Day to day:

    dfu                 # pull, preview the diff, confirm, apply, then update everything
    chezmoi diff        # what would change?
    chezmoi apply       # deploy
    just --list --list-submodules   # the update fan-out (just deploys nothing)
    just doctor                     # health-check this machine

See `docs/chezmoi-workflows.md` for adding and removing tools, changing
settings, and the gotchas.
