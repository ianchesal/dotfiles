#!/usr/bin/env bash
# Lay down just the standalone tmux-lite config on a machine you don't want to
# (or can't) fully chezmoi-manage: no git required, no Homebrew, no sudo, no
# TPM, no repo checkout. Fetches the single config file straight from GitHub
# and writes it to ~/.tmux.conf. The companion to bash-only.sh.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ianchesal/dotfiles/main/bootstrap/tmux-lite.sh | bash
#
# An existing ~/.tmux.conf is backed up (not silently replaced) before being
# overwritten, since a box you don't own may already have real content in it.
set -euo pipefail

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/ianchesal/dotfiles/main}"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

log()  { printf "\n${BOLD}${GREEN}==>%s${RESET}\n" " $*"; }
note() { printf "  ${YELLOW}[BACKUP]${RESET} %s\n" "$*"; }
warn() { printf "  ${YELLOW}[WARN]${RESET} %s\n" "$*"; }

# Downloads $1 (a path under the repo root) to $2 (a local destination path),
# backing $2 up first if it already exists.
fetch() {
  local src="$1" dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    note "$dest -> $dest$BACKUP_SUFFIX"
    cp "$dest" "$dest$BACKUP_SUFFIX"
  fi
  curl -fsSL "$REPO_RAW/$src" -o "$dest"
}

log "Installing tmux-lite config from $REPO_RAW"

fetch "home/dot_config/tmux/tmux-lite.conf" "$HOME/.tmux.conf"

# tmux 3.1+ loads every default config file it finds, not just the first, so an
# XDG config left behind would be layered on top of this one.
xdg_conf="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
if [[ -e "$xdg_conf" ]]; then
  warn "$xdg_conf also exists and tmux will load it after ~/.tmux.conf -- move it aside for a clean tmux-lite"
fi

if ! command -v tmux >/dev/null 2>&1; then
  warn "tmux is not installed on this machine yet; the config will be picked up once it is"
fi

log "Done. Start a new tmux server, or run 'tmux source-file ~/.tmux.conf' in a running one."
