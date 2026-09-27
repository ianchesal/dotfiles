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
# already have real content in them. Files that are already up to date are
# left alone, so rerunning it is how you update. Once installed, `dfu`
# (bashrc.d/09-parachute.bash) does that rerun for you, along with tmux-lite.
set -euo pipefail

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/ianchesal/dotfiles/main}"
BASHRC_D_MODULES="01-history.bash 02-shopts.bash 03-env.bash 04-aliases.bash 05-prompt.bash 06-completion.bash 07-fzf.bash 08-git.bash 09-parachute.bash"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

log()  { printf "\n${BOLD}${GREEN}==>%s${RESET}\n" " $*"; }
note() { printf "  ${YELLOW}[BACKUP]${RESET} %s\n" "$*"; }
updated()   { printf "  ${GREEN}[UPDATED]${RESET} %s\n" "$*"; }
unchanged() { printf "  [UNCHANGED] %s\n" "$*"; }

# Downloads $1 (a path under the repo root) to $2 (a local destination path).
# A file that is already identical is left alone, so rerunning to update a
# machine doesn't leave a backup of every unchanged file behind; one that
# differs is backed up first, then replaced.
fetch() {
  local src="$1" dest="$2" tmp
  tmp="$(mktemp "$dest.XXXXXX")"
  if ! curl -fsSL "$REPO_RAW/$src" -o "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  if [[ -f "$dest" ]] && cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"
    unchanged "$dest"
    return 0
  fi
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    note "$dest -> $dest$BACKUP_SUFFIX"
    cp "$dest" "$dest$BACKUP_SUFFIX"
  fi
  # Write into place rather than mv: keeps the old write-through-a-symlink behaviour and the
  # umask permissions curl -o gave, where mktemp would leave it 0600.
  cat "$tmp" > "$dest"
  rm -f "$tmp"
  updated "$dest"
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
