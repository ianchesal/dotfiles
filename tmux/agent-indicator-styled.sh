#!/usr/bin/env bash
# Wrapper around tmux-agent-indicator that adds styled segment only when active.
# Uses double powerline separators with a thin dark gap to match the left status bar style.

set -euo pipefail

PLUGIN_DIR="${TMUX_AGENT_INDICATOR_DIR:-$HOME/.config/tmux/plugins/tmux-agent-indicator}"
INDICATOR_SCRIPT="$PLUGIN_DIR/scripts/indicator.sh"

if [ ! -x "$INDICATOR_SCRIPT" ]; then
    exit 0
fi

icon=$("$INDICATOR_SCRIPT")

# U+E0B2 (Powerline left arrow) in UTF-8: 0xEE 0x82 0xB2
SEP=$(printf '\xee\x82\xb2')

if [ -n "$icon" ]; then
    # Double-sep: datetime(#353535) → dark gap → agent(#be95ff)
    # Double-sep: agent(#be95ff) → dark gap → hostname(#78a9ff)
    printf '%s' \
        "#[fg=#161616,bg=#353535,nobold,nounderscore,noitalics]${SEP}" \
        "#[fg=#be95ff,bg=#161616]${SEP}" \
        "#[fg=#161616,bg=#be95ff] ${icon} " \
        "#[fg=#161616,bg=#be95ff,nobold,nounderscore,noitalics]${SEP}" \
        "#[fg=#78a9ff,bg=#161616]${SEP}"
else
    # Double-sep: datetime(#353535) → dark gap → hostname(#78a9ff)
    printf '%s' \
        "#[fg=#161616,bg=#353535,nobold,nounderscore,noitalics]${SEP}" \
        "#[fg=#78a9ff,bg=#161616]${SEP}"
fi
