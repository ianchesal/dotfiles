# Refresh a parachute machine -- one set up with bootstrap/bash-only.sh
# and bootstrap/tmux-lite.sh rather than chezmoi -- to the latest bash
# and tmux-lite config on main. `dfu` here is the bash twin of the zsh
# dfu, for boxes where that one doesn't exist.
#
# Fetches by commit hash, not by `main`: raw.githubusercontent.com caches
# a branch URL for several minutes, so pulling right after a push can
# silently lay down the old files. A commit URL can never be stale.
#
# DOTFILES_REPO_RAW overrides the base URL outright (skipping the hash
# lookup), e.g. to pin a specific commit or point at a file:// checkout.
parachute_update() {
  local chezmoi_dir="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"
  if [[ -z "${FORCE:-}" && ( -f "$chezmoi_dir/chezmoi.toml" || -f "$chezmoi_dir/chezmoistate.boltdb" ) ]]; then
    echo "parachute_update: this machine is chezmoi-managed; update it with dfu from zsh (or 'chezmoi update')." >&2
    echo "  Overwriting chezmoi's files from here would put them out of step with its source. FORCE=1 overrides." >&2
    return 1
  fi

  local repo_raw="${DOTFILES_REPO_RAW:-}"
  if [[ -z "$repo_raw" ]]; then
    local sha
    sha="$(curl -fsSL -H 'Accept: application/vnd.github.sha' \
      https://api.github.com/repos/ianchesal/dotfiles/commits/main 2>/dev/null)"
    if [[ "$sha" =~ ^[0-9a-f]{40}$ ]]; then
      repo_raw="https://raw.githubusercontent.com/ianchesal/dotfiles/$sha"
      echo "==> Updating to ${sha:0:8} (latest main)"
    else
      # The unauthenticated API allows 60 requests an hour; past that, fall
      # back to the branch URL and accept it may lag a recent push.
      repo_raw="https://raw.githubusercontent.com/ianchesal/dotfiles/main"
      echo "==> Couldn't resolve main's commit; using the branch URL, which may lag a push by a few minutes" >&2
    fi
  fi

  # Download each installer before running it: `curl | bash` would run an
  # empty script and report success if the download failed.
  local installer script
  for installer in bash-only.sh tmux-lite.sh; do
    script="$(curl -fsSL "$repo_raw/bootstrap/$installer")" || {
      echo "parachute_update: failed to download $installer from $repo_raw" >&2
      return 1
    }
    REPO_RAW="$repo_raw" bash -c "$script" || return 1
  done

  if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
    tmux source-file "$HOME/.tmux.conf" && echo "==> Reloaded tmux config"
  fi
  echo "==> Run 'exec bash -l' to load the new bash config into this shell"
}

alias dfu=parachute_update
