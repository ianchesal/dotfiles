#!/usr/bin/env bash
# Directories Rake used to create that hold no tracked files. chezmoi only
# creates directories containing managed entries, and git cannot track an
# empty directory, so a fresh clone has no other way to produce these.
set -euo pipefail

# NOTE: this runs against the real $HOME even when chezmoi is invoked with
# --destination. Apply with --exclude=scripts when targeting a scratch dir.
for d in \
  "$HOME/.cache/completions" \
  "$HOME/.local/share/zsh" \
  "$HOME/.tmux/plugins" \
  "$HOME/.gem" \
  "$HOME/.npm-global"
do
  [ -d "$d" ] || { mkdir -p "$d"; echo "created $d"; }
done
