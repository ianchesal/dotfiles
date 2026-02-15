#!/usr/bin/env bash
# Wrapper around tmux-agent-indicator that adds styled segment only when active.
# Outputs a purple (#be95ff) powerline segment with the agent icon, or nothing.

set -euo pipefail

PLUGIN_DIR="${TMUX_AGENT_INDICATOR_DIR:-$HOME/.config/tmux/plugins/tmux-agent-indicator}"
INDICATOR_SCRIPT="$PLUGIN_DIR/scripts/indicator.sh"

if [ ! -x "$INDICATOR_SCRIPT" ]; then
    exit 0
fi

icon=$("$INDICATOR_SCRIPT")

if [ -n "$icon" ]; then
    # Powerline left separator, purple bg segment, then transition to hostname blue
    printf '#[fg=#be95ff,bg=#353535,nobold,nounderscore,noitalics]\ue0b2#[fg=#161616,bg=#be95ff] %s #[fg=#78a9ff,bg=#be95ff,nobold,nounderscore,noitalics]\ue0b2' "$icon"
else
    # No agent active — output the normal transition from datetime to hostname
    printf '#[fg=#78a9ff,bg=#353535,nobold,nounderscore,noitalics]\ue0b2'
fi
