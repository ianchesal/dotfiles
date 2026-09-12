if (( $+commands[bat] )); then
  alias bat='bat --theme=TwoDark'
  alias cat=bat
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  battail() {
    tail -f "$@" | bat --paging=never -l log
  }
fi
