I use Homebrew's vim:

    brew uninstall vim; rvm system; brew install vim; rvm use 2.1.2

That `rvm system` is necessary otherwise `vim` segfaults when you try to use Ruby.

You need to clone [Vundle](https://github.com/gmarik/Vundle.vim#about) before this `vimrc` will work:

    git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim

and then you install plugins from within `vim` with:

    :PluginInstall

or from the command line:

    vim +PluginInstall +qall

To complete the YCM installtion you also need tod:

    cd ~/.vim/bundle/YouCompleteMe
    ./install.sh