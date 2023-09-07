# eza: https://github.com/eza-community/eza
if _has eza; then
  unalias ls
  unalias ll
  unalias la
  unalias ldot

  alias ls=eza
  alias l1='ls -1 --group-directories-first'
  alias ll='ls -l'
  alias la='ls -la'
  alias lg='ls -la --git'

  et() {
    eza -alT --git -I'.git|node_modules|.mypy_cache|.pytest_cache|.venv' --color=always "$@" | less -R;
  }
  alias et1='et -L1'
  alias et2='et -L2'
  alias et3='et -L3'
fi
