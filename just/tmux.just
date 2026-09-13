set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# The tmux config lives in home/dot_config/tmux/ and is deployed by chezmoi.
# What survives here are the two utility tasks that have no chezmoi equivalent.

# Reload the tmux configuration in every running session
reload:
    #!/usr/bin/env bash
    set -euo pipefail
    config=$HOME/.config/tmux/tmux.conf
    count=0
    # Read session names on NUL-free lines and quote every use: a session name
    # may contain spaces, so this must never become a built shell string.
    while IFS= read -r session; do
      [ -n "$session" ] || continue
      printf 'Reloading config for session: %s\n' "\"$session\""
      tmux source-file -t "$session" "$config"
      count=$((count + 1))
    done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
    printf 'Reloaded tmux configuration for %d session(s)\n' "$count"

# Print a 24-bit colour test pattern in this terminal
test-terminal:
    @bash "$HOME/.config/tmux/24-bit-color.sh"
