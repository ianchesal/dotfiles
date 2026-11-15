#!/usr/bin/env bash
#
# Enable or disable saved herdr machines from an fzf picker, by label.
#
# `herdr machine enable|disable` takes only the 32-hex profile id, and herdr's
# zsh completion offers filenames there, so this picks by label and maps it
# to the id. Bound in config.toml as a popup (prefix+m).
#
# Enter toggles the highlighted machine (Tab marks several to toggle together),
# and the list redraws with the new state. Esc closes the popup.
#
#   machines.sh               the picker
#   machines.sh --list        one line per machine: id, state, label, target
#   machines.sh toggle ID...  flip each id between enabled and disabled
#
# Seam for script/tests/herdr-machines.test.sh:
#   HERDR_BIN -- herdr executable (default: $HERDR_BIN_PATH, else herdr on PATH)

set -euo pipefail

# herdr injects its binary path, but a brew upgrade under a running server
# leaves it pointing at a deleted Cellar path -- fall back to PATH.
herdr=${HERDR_BIN:-${HERDR_BIN_PATH:-herdr}}
[ -x "$herdr" ] || herdr=herdr
export HERDR_BIN=$herdr

list_machines() {
  "$herdr" machine list --json |
    jq -r '.[] | [.id, (if .enabled then "enabled" else "disabled" end), .label, .target] | @tsv' |
    awk -F '\t' '{ printf "%s\t%-8s\t%s\t%s\n", $1, $2, $3, $4 }'
}

toggle() {
  local id state rc=0
  for id in "$@"; do
    state=$("$herdr" machine list --json | jq -r --arg id "$id" '.[] | select(.id == $id) | .enabled')
    case $state in
      true) "$herdr" machine disable "$id" >/dev/null || rc=1 ;;
      false) "$herdr" machine enable "$id" >/dev/null || rc=1 ;;
      *)
        echo "machines: no saved machine with id $id" >&2
        rc=1
        ;;
    esac
  done
  return "$rc"
}

pick() {
  local self opts
  self=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
  # FZF_DEFAULT_OPTS sets --tmux; if herdr itself runs inside tmux, fzf would
  # try to open a tmux popup of its own. Render inline in herdr's popup instead.
  opts=$(echo "${FZF_DEFAULT_OPTS:-}" | sed -E 's/--tmux(=[^ ]+)?( [a-z]+)?//')
  # The id is column 1: passed to toggle, never shown.
  list_machines | FZF_DEFAULT_OPTS="$opts" fzf --multi --delimiter '\t' --with-nth 2.. \
    --prompt 'machine> ' --header 'enter: toggle (tab marks several)  esc: close' \
    --bind "enter:execute-silent('$self' toggle {+1})+reload('$self' --list)+clear-selection" ||
    true
}

case ${1:-} in
  --list) list_machines ;;
  toggle)
    shift
    toggle "$@"
    ;;
  '') pick ;;
  *)
    echo "usage: machines.sh [--list | toggle ID...]" >&2
    exit 2
    ;;
esac
