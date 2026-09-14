# dotfiles/bootstrap

Standalone shell scripts that prepare a fresh machine to the point where the
rest of the dotfiles (chezmoi, then `just update`) can take over. These are run
by hand, not by `just`.

## Layout

```
centos.sh             Minimal CentOS/RHEL bootstrap: clones pyenv + rbenv (with
                      their plugins) and yum-installs tmux and neovim
cloud-workstation.sh  Idempotent provisioning for a Linux cloud workstation
bash-only.sh          Lays down just the standalone bash fallback config --
                      no git, no chezmoi, no Homebrew, no repo checkout
```

`cloud-workstation.sh` runs in numbered, re-runnable steps (each skips if
already satisfied): install chezmoi, `chezmoi init --apply` (which installs
Homebrew and the whole Brewfile via `run_once_before_20-brew-bundle.sh`, deploys
the configs and runs the `run_once_after` scripts), `just shell::set-default`,
`just install-runtimes`, the `xterm-kitty` terminfo, and finally `just doctor`.

It used to do Homebrew, the Brewfile, `/etc/shells`, `chsh`, asdf and a pinned
Ruby by hand — all of that moved into chezmoi or into a `just` recipe, so this
is now a thin wrapper over the same path a fresh machine takes.

`bash-only.sh` is the odd one out: it does not expect a repo checkout at all.
It fetches only the handful of files the standalone bash config needs
directly from GitHub's raw content and writes them into place, backing up
anything already at those paths first. Meant for root shells, minimal or
embedded boxes, and remote servers you don't want to (or can't) fully
chezmoi-manage.

## Usage

Run `centos.sh` or `cloud-workstation.sh` directly on the target machine,
e.g. `bash bootstrap/centos.sh` or `./bootstrap/cloud-workstation.sh`. They
expect the repo checked out at `$HOME/src/dotfiles` and may invoke `sudo`.

`bash-only.sh` needs no checkout and no `sudo` -- run it straight from GitHub:

```sh
curl -fsSL https://raw.githubusercontent.com/ianchesal/dotfiles/main/bootstrap/bash-only.sh | bash
```
