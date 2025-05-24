# eza: https://github.com/eza-community/eza
if (( $+commands[eza] )); then
  unalias l
  unalias ls
  unalias ll
  unalias la
  unalias ldot

  alias l1='eza -1 --group-directories-first'
  alias l='eza -1 --group-directories-first'
  alias la='eza -la --group-directories-first'
  alias lg='eza -la --git --group-directories-first'
  alias ll='eza -la --group-directories-first'
  alias ls='eza -1 --group-directories-first'

  et() {
    eza -alT --git -I'.git|node_modules|.mypy_cache|.pytest_cache|.venv' --color=always "$@" | less -R
  }
  alias et1='et -L1'
  alias et2='et -L2'
  alias et3='et -L3'
fi
