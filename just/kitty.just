set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Upstream source for kitty's terminfo entry. A remote box that never had kitty
# installed doesn't know TERM=xterm-kitty, so ssh'ing in from kitty gets broken
# line editing, colours and `clear` until this is compiled into ~/.terminfo.
terminfo_url := "https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo"

# Install the xterm-kitty terminfo entry into ~/.terminfo (no-op if already known; FORCE=1 reinstalls)
terminfo:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z "${FORCE:-}" ]] && infocmp xterm-kitty &>/dev/null; then
      echo 'xterm-kitty terminfo already installed'
      exit 0
    fi
    command -v tic >/dev/null || { echo 'tic not found (install ncurses-bin)' >&2; exit 1; }
    curl -fsSL '{{ terminfo_url }}' | tic -x -o "$HOME/.terminfo" -
    infocmp xterm-kitty >/dev/null
    echo "Installed xterm-kitty terminfo into $HOME/.terminfo"
