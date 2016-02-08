#!/bin/sh
if [ ! -d "${HOME}/.vim/bundle/Vundle.vim" ]; then
  git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
cd ~/.vim/bundle/Vundle.vim
git pull
vim +PluginInstall +qall
cd ~/.vim/bundle/YouCompleteMe
./install.sh
