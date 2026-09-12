#!/usr/bin/env bash
# Battery/UPS status widget for the tmux status bar.
# - macOS: reads laptop battery via pmset
# - Linux: reads UPS via NUT (upsc myups)
# - WSL2: outputs nothing

grep -qi microsoft /proc/version 2>/dev/null && exit 0

get_color() {
    local pct=$1 on_power=$2
    if [ "$on_power" = "1" ]; then
        echo "#42be65"
    elif [ "$pct" -ge 50 ]; then
        echo "#42be65"
    elif [ "$pct" -ge 20 ]; then
        echo "#ffcc66"
    else
        echo "#ff7eb6"
    fi
}

emit() {
    local pct=$1 on_power=$2
    local color icon
    color=$(get_color "$pct" "$on_power")
    icon=$( [ "$on_power" = "1" ] && echo "⚡" || echo "🔋" )
    printf "#[fg=%s]#[bg=#161616] %s %s%% " "$color" "$icon" "$pct"
}

if [ "$(uname)" = "Darwin" ]; then
    batt=$(pmset -g batt 2>/dev/null)
    pct=$(echo "$batt" | grep -o '[0-9]\+%' | head -1 | tr -d '%')
    [ -z "$pct" ] && exit 0
    echo "$batt" | grep -q "AC Power\|charging\|charged" && on_power=1 || on_power=0
    emit "$pct" "$on_power"
    exit 0
fi

if command -v upsc >/dev/null 2>&1; then
    pct=$(upsc myups battery.charge 2>/dev/null)
    [ -z "$pct" ] && exit 0
    status=$(upsc myups ups.status 2>/dev/null)
    echo "$status" | grep -q "OL" && on_power=1 || on_power=0
    emit "$pct" "$on_power"
fi
