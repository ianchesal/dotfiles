#!/bin/sh

# Complete a WSL2 Debian 10 setup

# Update Debian package libraries
sudo apt update
sudo apt upgrade

# Install things I like
sudo apt install \
	zsh \
	zsh-syntax-highlighting \
	ripgrep \
	tmux \
	neovim \
	fzf \
	git \
	curl \
	jq \
	libssl-dev \
	libreadline-dev \
	zlib1g-dev \
	autoconf \
	bison \
	build-essential \
	libyaml-dev \
	libreadline-dev \
	libncurses5-dev \
	libffi-dev \
	libgdbm-dev

# Install rbenv, ruby-build
curl -sL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash -
# TODO: Figure out how to install ruby version I like
# rbenv install 2.7.2
# rbenv global 2.7.2

# Install pyenv, pyenv-virtualenv
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
# TODO: Figure out how to auto-install python verison I like
# pyenv install 3.9.1
# pyenv global 3.9.1

# You need to install these fonts by hand to get PowerLine10k working and edit the
# Windows Terminal settings.json file
# http://iamnotmyself.com/2017/04/15/setting-up-powerline-shell-on-windows-subsystem-for-linux/
# I like InconsolataGo NF from here:
# https://www.nerdfonts.com/font-downloads

# Mount points I need
sudo mkdir /mnt/ian /mnt/media
