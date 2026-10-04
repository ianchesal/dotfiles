#!/usr/bin/env bash
# Clone tpm if it isn't already there, then install the plugins tmux.conf
# declares. Ported from the tmux:plugins rake task.
#
# This is deliberately NOT a .chezmoiexternal.toml git-repo entry. An external
# would be re-validated on every `chezmoi diff`, `apply` and `verify` -- and dfu
# runs diff daily -- and if the directory exists but is not a clean git repo the
# external fails, which fails the ENTIRE apply. A run_once clone has neither
# problem, and tpm updates come from `prefix + U` regardless.
#
# NOTE: runs against the real $HOME even when chezmoi is given --destination.
set -euo pipefail
dir="$HOME/.config/tmux/plugins/tpm"
if [ -d "$dir/.git" ]; then
  echo "tpm already installed"
elif [ -e "$dir" ]; then
  echo "WARNING: $dir exists but is not a git clone - leaving it alone" >&2
else
  echo "Cloning tpm into $dir"
  mkdir -p "$(dirname "$dir")"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$dir"
fi

# Without this a fresh machine has tpm but no plugins until someone presses
# `prefix + I`, and the status bar shows a literal `#U` and the raw DHCP
# hostname because tmux-current-pane-hostname never loaded. install_plugins
# reads tmux.conf directly and needs no running server; it skips plugins that
# are already present, so re-running it is harmless.
if [ -x "$dir/bin/install_plugins" ] && command -v tmux >/dev/null 2>&1; then
  "$dir/bin/install_plugins"
else
  echo "WARNING: tmux or tpm missing - skipping plugin install (prefix + I installs them later)" >&2
fi
