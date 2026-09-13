#!/usr/bin/env bash
# Provision a Linux cloud workstation from nothing to a working setup.
#
# Idempotent: every step skips if already satisfied, so re-running is safe.
#
# This used to install Homebrew, run brew bundle, register zsh, chsh, source
# asdf and install a pinned Ruby by hand -- eight steps that predated chezmoi.
# chezmoi now owns provisioning: `chezmoi init --apply` runs
# home/run_once_before_20-brew-bundle.sh, which installs Homebrew and everything
# in brew/Brewfile before any config lands. What survives here is the handful of
# things chezmoi deliberately does not do: the one that needs sudo and can lock
# you out (the login shell), and the ones specific to a remote box.
set -euo pipefail

DOTFILES="$HOME/src/dotfiles"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

log()    { echo -e "\n${BOLD}${GREEN}==> $*${RESET}"; }
skip()   { echo -e "  ${YELLOW}[SKIP]${RESET} $*"; }
# Prints a [RUN] banner — logging only, does NOT execute a command
action() { echo -e "  ${GREEN}[RUN]${RESET} $*"; }

# Put Homebrew on PATH for the rest of this script once it exists.
use_brew() {
  local candidate
  for candidate in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew" \
    /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done
  return 1
}

# ── Step 1: Install chezmoi ───────────────────────────────────────────────────
# A static binary that ships its own git, so it has no prerequisites of its own.
log "Step 1: Install chezmoi"
if command -v chezmoi &>/dev/null; then
  skip "chezmoi already installed"
else
  action "Installing chezmoi to ~/.local/bin"
  sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
fi

# ── Step 2: chezmoi init --apply ──────────────────────────────────────────────
# Does the heavy lifting: clones the repo, installs Homebrew and every Brewfile
# package via run_once_before_20-brew-bundle.sh, deploys the configs, then runs
# the run_once_after scripts (tpm, gh extensions, permissions, empty dirs).
log "Step 2: chezmoi init --apply"
if [[ -d "$DOTFILES/.git" ]] && chezmoi source-path &>/dev/null; then
  action "Already initialised; applying"
  chezmoi apply
else
  action "Running chezmoi init --apply --source=$DOTFILES"
  chezmoi init --apply --source="$DOTFILES" ianchesal/dotfiles
fi

use_brew || { echo "ERROR: Homebrew not found after chezmoi apply" >&2; exit 1; }

# ── Step 3: Make Homebrew zsh the login shell ─────────────────────────────────
# Kept out of chezmoi on purpose: it needs sudo, and it is the one step that can
# lock you out of a box. `just shell::set-default` is idempotent.
log "Step 3: Make Homebrew zsh the login shell"
action "Running just shell::set-default"
just --justfile "$DOTFILES/justfile" shell::set-default

# ── Step 4: Install the asdf-managed runtimes ─────────────────────────────────
# Versions come from ~/.tool-versions, not hardcoded here.
log "Step 4: Install asdf runtimes"
action "Running just install-runtimes"
just --justfile "$DOTFILES/justfile" install-runtimes

# ── Step 5: Install kitty terminfo ────────────────────────────────────────────
# Remote boxes need this to accept a kitty client's TERM.
log "Step 5: Install kitty terminfo"
if infocmp xterm-kitty &>/dev/null; then
  skip "xterm-kitty terminfo already installed"
else
  action "Fetching and installing kitty.terminfo"
  curl -fsSL https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo |
    tic -x -o "$HOME/.terminfo" -
fi

# ── Step 6: Health check ──────────────────────────────────────────────────────
log "Step 6: Verify the result"
just --justfile "$DOTFILES/justfile" doctor || true

echo ""
echo -e "${BOLD}${GREEN}Bootstrap complete!${RESET}"
echo "Next steps:"
echo "  - Log out and back in for the new shell (zsh) to take effect"
echo "  - Use 'dfu' from then on to pull, apply and update everything"
