# dotfiles/debian

One-off provisioning for Debian 10, originally written for a WSL2 install but
usable on any Debian 10 release. Run by hand, not by rake.

## Layout

```
setup.sh   apt update/upgrade, installs preferred packages, sets up version managers
```

`setup.sh` updates the package lists, installs the tools used by this dotfiles
setup (zsh, ripgrep, tmux, neovim, fzf, git, plus the build dependencies for
compiling Ruby), installs `rbenv`/`ruby-build` and `pyenv`/`pyenv-virtualenv`
via their official installers, and creates the `/mnt/ian` and `/mnt/media`
mount points. Nerd Font installation and Windows Terminal `settings.json`
tweaks are noted in the script as manual steps.

## Usage

Run directly on the target machine: `./debian/setup.sh`. It invokes `sudo` for
the apt and mount-point steps.
