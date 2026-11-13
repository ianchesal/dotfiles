#!/usr/bin/env bash
# Lay down the herdr config on a machine you don't want to (or can't) fully
# chezmoi-manage: no git, no Homebrew, no sudo, no repo checkout. The companion
# to bash-only.sh and tmux-lite.sh, and rerun by the bash parachute's `dfu`.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ianchesal/dotfiles/main/bootstrap/herdr-lite.sh | bash
#
# Why a remote box needs this at all: the herdr *server* handles keys, so when a
# local herdr attaches a remote session (`herdr machine enable`, `herdr
# --remote`) the remote server's config decides what a key does. Without this
# file there, Ctrl-h/j/k/l and every other custom binding fall through to the
# shell. These are the same files chezmoi deploys -- not a trimmed copy -- so
# they never drift; bindings whose tools are missing (lazygit, fzf, gh-dash)
# just fail when pressed. nav.sh, the Ctrl-h/j/k/l half, needs only jq.
#
# Existing files that differ are backed up before being replaced; identical
# ones are left alone. A running herdr server reloads the new config.
set -euo pipefail

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/ianchesal/dotfiles/main}"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"
HERDR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/herdr"
SCRIPTS=(nav.sh open-repo.sh add-worktree.sh open-worktree.sh remove-worktree.sh)

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

log()  { printf "\n${BOLD}${GREEN}==>%s${RESET}\n" " $*"; }
note() { printf "  ${YELLOW}[BACKUP]${RESET} %s\n" "$*"; }
updated()   { printf "  ${GREEN}[UPDATED]${RESET} %s\n" "$*"; }
unchanged() { printf "  [UNCHANGED] %s\n" "$*"; }
warn() { printf "  ${YELLOW}[WARN]${RESET} %s\n" "$*"; }

# Downloads $1 (a path under the repo root) to $2 (a local destination path).
# Same contract as tmux-lite.sh's fetch: identical files are left alone, ones
# that differ are backed up first, then replaced.
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
  cat "$tmp" > "$dest"
  rm -f "$tmp"
  updated "$dest"
}

log "Installing herdr config from $REPO_RAW"

mkdir -p "$HERDR_DIR"
fetch "home/dot_config/herdr/config.toml" "$HERDR_DIR/config.toml"
for script in "${SCRIPTS[@]}"; do
  fetch "home/dot_config/herdr/executable_$script" "$HERDR_DIR/$script"
  chmod +x "$HERDR_DIR/$script"
done

if ! command -v jq >/dev/null 2>&1; then
  warn "jq is not installed; Ctrl-h/j/k/l (nav.sh) needs it to move between panes"
fi

# `herdr machine add` installs herdr to ~/.local/bin, which a non-interactive
# shell often doesn't have on PATH.
herdr_bin="$(command -v herdr 2>/dev/null || true)"
[[ -z "$herdr_bin" && -x "$HOME/.local/bin/herdr" ]] && herdr_bin="$HOME/.local/bin/herdr"

if [[ -z "$herdr_bin" ]]; then
  warn "herdr is not installed on this machine yet; the config will be picked up once it is"
elif ! "$herdr_bin" config check >/dev/null; then
  warn "herdr config check failed (this herdr may be older than the config); not reloading"
# The API socket, not pgrep: dfu runs this script as `bash -c "$script"`, so a
# process match on 'herdr server' would find this very script.
elif [[ -S "$HERDR_DIR/herdr.sock" ]]; then
  if "$herdr_bin" server reload-config >/dev/null; then
    log "Reloaded the running herdr server's config"
  else
    warn "couldn't reload the running herdr server; run '$herdr_bin server reload-config'"
  fi
fi

log "Done."
