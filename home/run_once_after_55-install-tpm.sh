#!/usr/bin/env bash
# Clone tpm if it isn't already there. Ported from the tmux:plugins rake task.
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
