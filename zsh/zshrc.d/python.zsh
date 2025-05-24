# Set up pyenv root without initializing (for performance)
command -v pyenv &>/dev/null && FOUND_PYENV=1 || FOUND_PYENV=0
if [[ $FOUND_PYENV -eq 1 ]]; then
  export PYENV_ROOT=$(pyenv root)
else
  export PYENV_ROOT="$HOME/.pyenv"
fi
unset FOUND_PYENV
export PIPENV_IGNORE_VIRTUALENVS=1

# Add pyenv to PATH if not already available
if ! (( $+commands[pyenv] )); then
  path+="$PYENV_ROOT/bin"
fi

# Lazy load pyenv to improve shell startup performance
# Only initialize when python/pip/pyenv commands are first used
__pyenv_lazy_load() {
  unfunction python python3 pip pip3 pyenv 2>/dev/null
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
  # Call the original command with all arguments
  "$1" "${@:2}"
}

# Create lazy-loading wrapper functions
if (( $+commands[pyenv] )); then
  python() { __pyenv_lazy_load python "$@" }
  python3() { __pyenv_lazy_load python3 "$@" }
  pip() { __pyenv_lazy_load pip "$@" }
  pip3() { __pyenv_lazy_load pip3 "$@" }
  pyenv() { __pyenv_lazy_load pyenv "$@" }
fi

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
