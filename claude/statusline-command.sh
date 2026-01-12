#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Colors matching Oh My Posh palette
BLUE='\033[38;2;120;169;255m'      # terminal-blue
GREEN='\033[38;2;66;190;101m'      # pistachio-green
RESET='\033[0m'

# Get shortened path (replace home with ~)
short_path="${cwd/#$HOME/\~}"

# Git information
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    # Get current branch
    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Check for changes
    if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
        status="*"
    else
        status=""
    fi

    # Check ahead/behind (skip optional locks)
    ahead_behind=""
    upstream=$(git -C "$cwd" rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    if [ -n "$upstream" ]; then
        ahead=$(git -C "$cwd" rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
        behind=$(git -C "$cwd" rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
        [ "$behind" != "0" ] && ahead_behind="↓"
        [ "$ahead" != "0" ] && ahead_behind="${ahead_behind}↑"
    fi

    git_info=" on ${GREEN}${branch}${status}${RESET} ${GREEN}${ahead_behind}${RESET}"
fi

# Build the status line
printf "${BLUE}${short_path}${RESET}${git_info}"
