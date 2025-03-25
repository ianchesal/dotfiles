command -v pyenv &>/dev/null && FOUND_PYENV=1 || FOUND_PYENV=0
if [[ $FOUND_PYENV -eq 1 ]]; then
  export PYENV_ROOT=$(pyenv root)
else
  export PYENV_ROOT="$HOME/.pyenv"
fi
unset FOUND_PYENV
export PIPENV_IGNORE_VIRTUALENVS=1

if ! type pyenv >/dev/null; then
  path+="$PYENV_ROOT/bin"
fi

if type pyenv >/dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"

  # Pipenv completion
  _pipenv() {
    eval $(env COMMANDLINE="${words[1, $CURRENT]}" _PIPENV_COMPLETE=complete-zsh pipenv)
  }
  compdef _pipenv pipenv

  # Automatic pipenv shell activation/deactivation
  _togglePipenvShell() {
    # deactivate shell if Pipfile doesn't exist and not in a subdir
    if [[ ! -f "$PWD/Pipfile" ]]; then
      if [[ "$PIPENV_ACTIVE" == 1 ]]; then
        if [[ "$PWD" != "$pipfile_dir"* ]]; then
          exit
        fi
      fi
    fi

    # activate the shell if Pipfile exists
    if [[ "$PIPENV_ACTIVE" != 1 ]]; then
      if [[ -f "$PWD/Pipfile" ]]; then
        export pipfile_dir="$PWD"
        pipenv shell
      fi
    fi
  }
  autoload -U add-zsh-hook
  add-zsh-hook chpwd _togglePipenvShell
  _togglePipenvShell
fi
