command -v pyenv &> /dev/null && FOUND_PYENV=1 || FOUND_PYENV=0
if [[ $FOUND_PYENV -eq 1 ]]; then
  export PYENV_ROOT=$(pyenv root)
fi
unset FOUND_PYENV
export PIPENV_IGNORE_VIRTUALENVS=1
