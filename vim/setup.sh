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

if  [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
  _echo_red "Missing Vundle"
  _echo_green "Installing Vundle for vim..."
  git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
else
  _echo_green "Updating Vundle..."
  pushd ~/.vim/bundle/Vundle.vim
  git pull
  popd
fi


python_versions=(2.7.16 3.7.4)

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
  _echo_green "Using: $(pyenv which python)"
  _echo_green "Upgrading pip and setuptools..."
  pip install --upgrade pip setuptools
  _echo_green "Installing pynvim support..."
  pip install pynvim
  if [ ${pyver%%.*} -eq 3 ]; then
    _echo_green "Installing flake8..."
    pip install flake8
    if [[ -f ~/bin/flake8 ]]; then
      rm -f ~/bin/flake8
    fi
    ln -s $(pyenv which flake8) ~/bin/flake8
    ls -lah ~/bin/flake8
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
  npm install -g neovim
else
  _echo_red "No npm detected. Node.js support not installed."
fi

_echo_green "Vim setup complete"
_echo_green "Now run: vim +PluginInstall +qall; vim +checkhealth"
