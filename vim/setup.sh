#!/usr/bin/env zsh
# Setup or refresh my environment for vim
# Assumes: brew install pyenv pyenv-virtualenv

RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

function _echo_green {
  echo -e "${GREEN}$*${NOCOLOR}"
}

function _echo_red {
  echo -e "${RED}$*${NOCOLOR}"
}

function _pyenv_has_version {
  pyenv versions | grep -q $1
}

# I no longer use Vundle so remove any trace of it
if  [[ -d ~/.vim/bundle ]]; then
  pushd ~/.vim
  rm -rf ./bundle
  popd
fi

python_versions=(3.8.2)

for pyver in $python_versions; do
  _pyenv_has_version $pyver || {
    _echo_red "Missing python $pyver in pyenv"
    _echo_green "Installing python $pyver in pyenv..."
    pyenv install $pyver
  }
  _echo_green "Creating virtualenv neovim${pyver%%.*} for ${pyver}"
  pyenv virtualenv --force ${pyver} neovim${pyver%%.*}
  _echo_green "Activiating neovim${pyver%%.*} python virtualenv..."
  pyenv activate neovim${pyver%%.*}
  # This ensures my work pip.conf and this venv can coexist peacefully
  _echo_green "Using: $(pyenv which python)"
cat > "${VIRTUAL_ENV}/pip.conf" <<- EOM
[global]
index = https://pypi.python.org/
index-url = https://pypi.python.org/simple
EOM
  _echo_green "Upgrading pip and setuptools..."
  pip install --upgrade pip setuptools
  _echo_green "Installing pynvim support..."
  pip install pynvim
  if [ ${pyver%%.*} -eq 3 ]; then
    for pypackage in (flake8 pylint); do
      _echo_green "Installing ${pypackage}..."
      pip install ${pypackage}
      if [[ -f ~/bin/${pypackage} ]]; then
        rm -f ~/bin/${pypackage}
      fi
    done
  fi
  pyenv deactivate
done

if whence gem > /dev/null ; then
  _echo_green "gem detected"
  _echo_green "Installing neovim support for Ruby..."
  gem install neovim
else
  _echo_red "No gem detected. Ruby support not installed."
fi

if whence npm > /dev/null; then
  _echo_green "npm detected"
  _echo_green "Installing neovim support for Node.js..."
  npm install --force -g neovim
else
  _echo_red "No npm detected. Node.js support not installed."
fi

if whence yarn > /dev/null; then
  _echo_green "yarn detected"
  _echo_green "Installing neovim support for Node.js..."
  yarn global add neovim
else
  _echo_red "No yarn detected. Node.js support not installed."
fi

_echo_green "Vim setup complete"
_echo_green "Now run: vim +PlugInstall +qall; vim +checkhealth"
