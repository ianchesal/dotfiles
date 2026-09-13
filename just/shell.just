set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Deliberately not a run_once script. Registering a shell needs sudo, and
# changing your login shell is the one bootstrap step that can lock you out of a
# machine if it goes wrong -- so it stays an explicit, re-runnable act rather
# than a side effect of `chezmoi apply`.

# Make Homebrew's zsh the login shell (registers it in /etc/shells first)
set-default:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v brew >/dev/null; then
      printf '\033[31m%s\033[0m\n' 'No brew found -- run `chezmoi apply` first to provision Homebrew'
      exit 1
    fi
    zsh_bin="$(brew --prefix)/bin/zsh"
    if [ ! -x "$zsh_bin" ]; then
      printf '\033[31mNo zsh at %s -- is it in brew/Brewfile?\033[0m\n' "$zsh_bin"
      exit 1
    fi
    if grep -qxF "$zsh_bin" /etc/shells; then
      printf '\033[34m%s already in /etc/shells\033[0m\n' "$zsh_bin"
    else
      printf '\033[32mAdding %s to /etc/shells (needs sudo)\033[0m\n' "$zsh_bin"
      printf '%s\n' "$zsh_bin" | sudo tee -a /etc/shells >/dev/null
    fi
    # $SHELL reflects the running shell, not the configured one; getent/dscl is
    # the login shell of record.
    current=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
    if [ "$current" = "$zsh_bin" ]; then
      printf '\033[32mLogin shell is already %s\033[0m\n' "$zsh_bin"
    else
      printf '\033[32mChanging login shell %s -> %s\033[0m\n' "${current:-unknown}" "$zsh_bin"
      chsh -s "$zsh_bin"
      printf '\033[33m%s\033[0m\n' 'Log out and back in for the new shell to take effect'
    fi
