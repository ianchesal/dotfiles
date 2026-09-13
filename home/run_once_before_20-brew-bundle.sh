#!/usr/bin/env bash
# Install Homebrew, then everything in brew/Brewfile.
#
# This is what makes the README's one-command install true. Without it a fresh
# machine gets every config file and none of the tools those configs are for: a
# zsh config with no zsh, and a `dfu` that calls a `just` that was never
# installed. Homebrew is where zsh, just, chezmoi, nvim, tmux and asdf come from.
#
# run_once_BEFORE, so the tools exist before their configs land.
#
# CHEZMOI_WORKING_TREE is the repo root. Note it is NOT CHEZMOI_SOURCE_DIR --
# .chezmoiroot makes that <repo>/home, and brew/ sits outside the source state.
# The fallback covers running this script by hand.
set -euo pipefail

repo=${CHEZMOI_WORKING_TREE:-$HOME/src/dotfiles}
brewfile=$repo/brew/Brewfile

if [ ! -r "$brewfile" ]; then
  echo "No Brewfile at $brewfile -- skipping Homebrew provisioning" >&2
  exit 0
fi

# Homebrew's installer needs both; a minimal Debian image has neither.
for prereq in curl git; do
  if ! command -v "$prereq" >/dev/null; then
    echo "ERROR: $prereq is required to install Homebrew. Install it and re-run 'chezmoi apply'." >&2
    exit 1
  fi
done

# brew is not on PATH yet on a fresh install, so probe the known prefixes.
find_brew() {
  if command -v brew >/dev/null; then
    command -v brew
    return 0
  fi
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

if ! brew_bin=$(find_brew); then
  echo "Installing Homebrew (this prompts for sudo)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if ! brew_bin=$(find_brew); then
    echo "ERROR: Homebrew installed but no brew binary found in any known prefix." >&2
    exit 1
  fi
fi

eval "$("$brew_bin" shellenv)"

# Homebrew 7 will not load formulae from a non-official tap until it is trusted,
# and the trust store is machine-local -- a fresh box starts empty, so `brew
# bundle` would fail on the third-party taps the Brewfile declares. Apply the
# repo's reviewed list first. Called directly, not through `just`: just is one
# of the things brew bundle is about to install.
trust_script=$repo/script/brew-trust
if [ -x "$trust_script" ]; then
  echo "Trusting third-party taps from $repo/brew/trusted"
  BREW_BIN=$brew_bin "$trust_script"
else
  echo "WARNING: no $trust_script -- brew bundle may fail on third-party taps" >&2
fi

echo "Installing packages from $brewfile"
# No --no-lock: current Homebrew dropped the flag and errors on it.
brew bundle install --file="$brewfile"
