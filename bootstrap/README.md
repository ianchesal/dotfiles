# dotfiles/bootstrap

Standalone shell scripts that prepare a fresh machine to the point where the
rest of the dotfiles (`rake all`) can take over. These are run by hand, not by
rake.

## Layout

```
centos.sh             Minimal CentOS/RHEL bootstrap: clones pyenv + rbenv (with
                      their plugins) and yum-installs tmux and neovim
cloud-workstation.sh  Idempotent provisioning for a Linux cloud workstation
```

`cloud-workstation.sh` runs in numbered, re-runnable steps (each step skips if
already satisfied): install Homebrew, `brew bundle install` from
`../brew/Brewfile`, register Homebrew zsh in `/etc/shells` and make it the
default shell, source asdf, install the pinned Ruby via asdf, run `rake zsh` to
lay down the zsh symlinks, and install the `xterm-kitty` terminfo. On
completion it prints next steps (re-login for zsh, then `rake all`).

## Usage

Run the script directly on the target machine, e.g. `bash bootstrap/centos.sh`
or `./bootstrap/cloud-workstation.sh`. They expect the repo checked out at
`$HOME/src/dotfiles` and may invoke `sudo`.
