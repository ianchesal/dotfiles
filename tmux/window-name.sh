#!/usr/bin/env bash
# Print a tmux window name for a directory: the basename of the enclosing git
# repository or worktree root, falling back to the directory's own basename when
# it is not inside a repo.
#
# Walks up looking for .git (a directory in a normal clone, a file in a worktree
# or submodule) rather than shelling out to git, since this runs once per
# auto-named window on every status-line refresh. Used by window-status-format
# in theme.conf and automatic-rename-format in tmux.conf.
set -uo pipefail

dir="${1:-$PWD}"

d="$dir"
while [[ -n $d ]]; do
  if [[ -e $d/.git ]]; then
    printf '%s\n' "${d##*/}"
    exit 0
  fi
  d="${d%/*}"
done

name="${dir##*/}"
printf '%s\n' "${name:-/}"
