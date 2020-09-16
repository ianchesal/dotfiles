#!/bin/sh

# My regular brew packages...
brew install \
  aspell \
  awscli \
  bash-completion \
  emacs \
  ffmpeg \
  fish \
  fzf \
  git \
  jq \
  keychain \
  mas \
  neovim \
  node \
  packer \
  packer-completion \
  perl \
  pyenv \
  pyenv-virtualenv \
  rbenv \
  ripgrep \
  ruby-build \
  terminal-notifier \
  tmux \
  tree \
  yarn \
  youtube-dl \
  zsh \
  zsh-syntax-highlighting

# brew install mysql
# brew install postgres

# Cask
brew install caskroom/cask/brew-cask
brew cask install vagrant
brew cask install virtualbox
brew cask install kaleidoscope
brew cask install xact
brew cask install jdownloader
#brew cask install google-cloud-sdk
#brew cask install handbrake
brew cask install 1password-cli
