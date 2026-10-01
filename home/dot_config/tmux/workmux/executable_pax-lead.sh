#!/usr/bin/env bash
#
# Start, or switch to, the machine-wide pax lead.
#
# There is exactly one lead per machine: tmux session "pax", one window also
# named "pax", one pane running pi rooted at ~/src. pax-dispatch.sh hands every
# worktree on the machine to it by workingDir, which pax accepts from a lead
# whose cwd is not itself a git repo (pax/src/sidekick/lane-cwd.ts only refuses
# subdirectories of the lead's own repo, and ~/src has none).
#
# The --session-id is what makes the lead cheap to kill and relaunch: the
# multi-day dispatcher context lives in pi's session store, not the pane. pi is
# the session's only process, so quitting it ends the session and re-running
# this resumes where it left off.
#
# Seams for script/tests/pax-lead.test.sh:
#   SRC_ROOT          -- the lead's cwd (default: $HOME/src)
#   TMUX_BIN          -- tmux executable (default: tmux)
#   PAX_BIN           -- pax/pi executable (default: pi)
#   PAX_COMPUTER_PORT -- the lead's Computer port (default: 8800)

set -euo pipefail

src_root=${SRC_ROOT:-$HOME/src}
tmux_bin=${TMUX_BIN:-tmux}
pax_bin=${PAX_BIN:-pi}
port=${PAX_COMPUTER_PORT:-8800}
session=pax

focus_session() {
  "$tmux_bin" switch-client -t "=$session" 2>/dev/null ||
    "$tmux_bin" attach-session -t "=$session"
}

start_lead() {
  if ! "$tmux_bin" has-session -t "=$session" 2>/dev/null; then
    # Checked explicitly: start_lead is called from a `||` context, which
    # disables errexit inside it.
    "$tmux_bin" new-session -d -s "$session" -n pax -c "$src_root" \
      "PAX_COMPUTER_PORT=$port $pax_bin --session-id pax" || {
      echo "pax-lead: could not create session '$session'" >&2
      return 1
    }
  fi
  focus_session
}

start_lead || {
  # Only pause when there is a tty to pause for: the popup needs the message to
  # stay on screen, but script/tests/pax-lead.test.sh would hang on it.
  if [ -t 0 ]; then
    echo
    echo "pax-lead failed. Press any key to close."
    read -r -n 1 -s
  fi
  exit 1
}
