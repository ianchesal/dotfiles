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
# left alone, so rerunning it is how you update. ~/.profile is edited rather
# than replaced: a marked block at the top re-execs real bash when the login
# shell is sh (Synology DSM), and the rest of the file is kept as is. Once installed, `dfu`
# (bashrc.d/09-parachute.bash) does that rerun for you, along with tmux-lite.
set -euo pipefail

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/ianchesal/dotfiles/main}"
BASHRC_D_MODULES="01-history.bash 02-shopts.bash 03-env.bash 04-aliases.bash 05-prompt.bash 06-completion.bash 07-fzf.bash 08-git.bash 09-parachute.bash 10-secrets.bash"
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

PROFILE_BEGIN='# >>> parachute sh->bash >>>'
PROFILE_END='# <<< parachute sh->bash <<<'

# The guard block for ~/.profile. Some boxes (Synology DSM) give every user
# /bin/sh with no chsh, and bash started as sh reads only ~/.profile, so
# ~/.bash_profile and this whole config never run. For an interactive login
# started as sh this re-execs a real bash login shell. It has to be POSIX sh
# (dash and ash read this file too), and it tests $0 rather than
# `shopt -o posix` because bash only enters POSIX mode *after* reading its
# startup files. A real bash has $0 = bash/-bash, so ~/.bash_profile sourcing
# ~/.profile can't loop; non-interactive readers (display managers, scp, rsync)
# never match; with no bash on PATH it does nothing.
profile_guard() {
  cat <<EOF
$PROFILE_BEGIN
# Managed by the dotfiles parachute (bootstrap/bash-only.sh): edits inside
# these markers are replaced on the next run. Interactive login shells started
# as sh re-exec as a real bash login shell.
case \$- in
  *i*)
    case \${0##*/} in
      sh|-sh) command -v bash >/dev/null 2>&1 && exec bash -l ;;
    esac
    ;;
esac
$PROFILE_END
EOF
}

# Puts the guard block at the top of ~/.profile without disturbing anything
# else in it. Debian/WSL ship a skel ~/.profile with PATH setup that
# ~/.bash_profile relies on, so the file is edited, never replaced. A previous
# block is removed first, so reruns update it in place instead of stacking
# copies. It goes first so a sh login switches to bash before the rest runs
# (bash then reads the whole file anyway); in a real bash it's a no-op.
install_profile_guard() {
  local dest="$HOME/.profile" tmp
  tmp="$(mktemp "$dest.XXXXXX")"
  {
    profile_guard
    if [[ -f "$dest" ]]; then
      awk -v b="$PROFILE_BEGIN" -v e="$PROFILE_END" '
        $0 == b { skip = 1; next }
        $0 == e && skip { skip = 0; next }
        !skip
      ' "$dest"
    fi
  } > "$tmp"
  if [[ -f "$dest" ]] && cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"
    unchanged "$dest"
    return 0
  fi
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    note "$dest -> $dest$BACKUP_SUFFIX"
    cp "$dest" "$dest$BACKUP_SUFFIX"
  fi
  cat "$tmp" > "$dest"
  rm -f "$tmp"
  updated "$dest"
}

log "Installing standalone bash config from $REPO_RAW"

mkdir -p "$HOME/.config/bash/bashrc.d"

fetch "home/dot_bashrc" "$HOME/.bashrc"
fetch "home/dot_bash_profile" "$HOME/.bash_profile"
fetch "home/dot_inputrc" "$HOME/.inputrc"
install_profile_guard
fetch "home/dot_config/bash/bashrc.sh" "$HOME/.config/bash/bashrc.sh"

for module in $BASHRC_D_MODULES; do
  fetch "home/dot_config/bash/bashrc.d/$module" "$HOME/.config/bash/bashrc.d/$module"
done

log "Done. Start a new login shell (or run 'exec bash -l') to pick it up."
