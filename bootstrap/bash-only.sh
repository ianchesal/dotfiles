#!/usr/bin/env bash
# Lay down just the standalone bash fallback config on a machine you don't
# want to (or can't) fully chezmoi-manage: no git required, no Homebrew, no
# sudo, no repo checkout. Fetches the handful of files this config needs
# straight from GitHub and writes them into place.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ianchesal/dotfiles/main/bootstrap/bash-only.sh | bash
#
# Existing ~/.bashrc, ~/.bash_profile, and ~/.inputrc are backed up (not
# silently replaced) before being overwritten, since a box you don't own may
# already have real content in them.
set -euo pipefail

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/ianchesal/dotfiles/main}"
BASHRC_D_MODULES="01-history.bash 02-shopts.bash 03-env.bash 04-aliases.bash 05-prompt.bash 06-completion.bash 07-fzf.bash"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

log()  { printf "\n${BOLD}${GREEN}==>%s${RESET}\n" " $*"; }
note() { printf "  ${YELLOW}[BACKUP]${RESET} %s\n" "$*"; }

# Downloads $1 (a path under the repo root, e.g. "home/dot_bashrc") to $2
# (a local destination path), backing $2 up first if it already exists.
fetch() {
  local src="$1" dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    note "$dest -> $dest$BACKUP_SUFFIX"
    cp "$dest" "$dest$BACKUP_SUFFIX"
  fi
  curl -fsSL "$REPO_RAW/$src" -o "$dest"
}

log "Installing standalone bash config from $REPO_RAW"

mkdir -p "$HOME/.config/bash/bashrc.d"

fetch "home/dot_bashrc" "$HOME/.bashrc"
fetch "home/dot_bash_profile" "$HOME/.bash_profile"
fetch "home/dot_inputrc" "$HOME/.inputrc"
fetch "home/dot_config/bash/bashrc.sh" "$HOME/.config/bash/bashrc.sh"

for module in $BASHRC_D_MODULES; do
  fetch "home/dot_config/bash/bashrc.d/$module" "$HOME/.config/bash/bashrc.d/$module"
done

log "Done. Start a new login shell (or run 'exec bash -l') to pick it up."
