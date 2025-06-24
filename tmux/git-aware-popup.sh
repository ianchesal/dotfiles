#!/bin/bash

# Script to determine the appropriate directory and name for a git-aware tmux popup
# If the current directory is inside a git repository, use the git root
# Otherwise, use the current working directory

current_path="$1"

# Check if we're in a git repository
if git -C "$current_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # We're in a git repo, get the root directory
    git_root=$(git -C "$current_path" rev-parse --show-toplevel)
    popup_dir="$git_root"
    popup_name="popup-$(basename "$git_root" | tr -cd "a-zA-Z0-9-")"
else
    # Not in a git repo, use current directory
    popup_dir="$current_path"
    popup_name="popup-$(basename "$current_path" | tr -cd "a-zA-Z0-9-")"
fi

echo "$popup_dir|$popup_name"