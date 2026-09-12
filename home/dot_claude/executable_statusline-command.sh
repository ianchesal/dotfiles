#!/bin/bash

# Read JSON input from stdin (consumed once, passed to either path)
input=$(cat)

if command -v oh-my-posh > /dev/null 2>&1; then
    echo "$input" | oh-my-posh claude --config ~/.config/ohmyposh/claude.json
    exit 0
fi

# Fallback: manual path + git rendering
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

BLUE='\033[38;2;120;169;255m'
GREEN='\033[38;2;66;190;101m'
RESET='\033[0m'

short_path="${cwd/#$HOME/\~}"

git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)

    if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
        status="*"
    else
        status=""
    fi

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

printf "${BLUE}${short_path}${RESET}${git_info}"
