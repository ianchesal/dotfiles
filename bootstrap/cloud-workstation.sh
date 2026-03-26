#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2034  # Used by subsequent steps appended to this file
DOTFILES="$HOME/src/dotfiles"

# Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

log() {
  echo -e "\n${BOLD}${GREEN}==> $*${RESET}"
}

skip() {
  echo -e "  ${YELLOW}[SKIP]${RESET} $*"
}

# Prints a [RUN] banner — logging only, does NOT execute a command
action() {
  echo -e "  ${GREEN}[RUN]${RESET} $*"
}

# ── Step 1: Install Homebrew ──────────────────────────────────────────────────
log "Step 1: Install Homebrew"
if command -v brew &>/dev/null; then
  skip "brew already installed"
else
  action "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Always eval shellenv so brew is in PATH for subsequent steps
BREW_BIN=/home/linuxbrew/.linuxbrew/bin/brew
if [[ ! -x "$BREW_BIN" ]]; then
  echo "ERROR: brew binary not found at $BREW_BIN" >&2
  exit 1
fi
eval "$($BREW_BIN shellenv)"

# ── Step 2: brew bundle install ───────────────────────────────────────────────
log "Step 2: brew bundle install"
if brew bundle check --file="$DOTFILES/brew/Brewfile" --no-lock &>/dev/null; then
  skip "All Brewfile packages already installed"
else
  action "Running brew bundle install"
  brew bundle install --file="$DOTFILES/brew/Brewfile" --no-lock
fi

# ── Step 3: Add Homebrew zsh to /etc/shells ───────────────────────────────────
log "Step 3: Add Homebrew zsh to /etc/shells"
BREW_ZSH="$(brew --prefix)/bin/zsh"
if grep -qF "$BREW_ZSH" /etc/shells; then
  skip "$BREW_ZSH already in /etc/shells"
else
  action "Adding $BREW_ZSH to /etc/shells"
  echo "$BREW_ZSH" | sudo tee -a /etc/shells > /dev/null
fi

# ── Step 4: Change default shell to Homebrew zsh ─────────────────────────────
log "Step 4: Change default shell to Homebrew zsh"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [[ "$CURRENT_SHELL" == "$BREW_ZSH" ]]; then
  skip "Default shell is already $BREW_ZSH"
else
  action "Running chsh -s $BREW_ZSH"
  chsh -s "$BREW_ZSH"
  echo "  Note: new shell takes effect on next login"
fi

# ── Step 5: Source asdf into this shell ───────────────────────────────────────
log "Step 5: Source asdf"
action "Sourcing asdf shell integration"
# shellcheck source=/dev/null
. "$(brew --prefix asdf)/libexec/asdf.sh"
echo "  asdf $(asdf version) available"

# ── Step 6: Install Ruby 3.3.9 via asdf ──────────────────────────────────────
log "Step 6: Install Ruby 3.3.9 via asdf"
RUBY_VERSION="3.3.9"
if asdf list ruby 2>/dev/null | grep -qE "^\s*${RUBY_VERSION}$"; then
  skip "Ruby $RUBY_VERSION already installed"
else
  action "Installing Ruby $RUBY_VERSION"
  asdf plugin add ruby || true
  asdf install ruby "$RUBY_VERSION"
  action "Setting Ruby $RUBY_VERSION as user-level default"
  asdf set -u ruby "$RUBY_VERSION"
fi

# ── Step 7: Set up zsh configuration ─────────────────────────────────────────
log "Step 7: Set up zsh configuration (rake zsh)"
ZSH_CONFIG_OK=false
ZSHENV_OK=false
[[ -L "$HOME/.config/zsh" && "$(readlink "$HOME/.config/zsh")" == "$DOTFILES/zsh" ]] && ZSH_CONFIG_OK=true
[[ -L "$HOME/.zshenv" && "$(readlink "$HOME/.zshenv")" == "$DOTFILES/zsh/.zshenv" ]] && ZSHENV_OK=true

if $ZSH_CONFIG_OK && $ZSHENV_OK; then
  skip "zsh symlinks already in place"
else
  action "Running rake zsh"
  (cd "$DOTFILES" && rake zsh)
fi

# ── Step 8: Install kitty terminfo ───────────────────────────────────────────
log "Step 8: Install kitty terminfo"
if infocmp xterm-kitty &>/dev/null; then
  skip "xterm-kitty terminfo already installed"
else
  action "Fetching and installing kitty.terminfo"
  curl -fsSL https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo | tic -x -o "$HOME/.terminfo" -
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}Bootstrap complete!${RESET}"
echo "Next steps:"
echo "  - Log out and back in for the new shell (zsh) to take effect"
echo "  - Run 'rake all' from $DOTFILES to finish setting up remaining dotfiles"
