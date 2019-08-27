function rpg {
  rg -p "$@" | less -R
}

function listpaths {
  echo "$PATH" | tr ':' '\n'
}

