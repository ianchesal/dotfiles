# Using Python with NeoVIM

I'm using NeoVIM now and it has nice python integrations. I've also switched to deoplete for completions which doesn't require a compiled plugin. To setup my Python 2 and 3 for NeoVIM I followed the instructions [here](https://github.com/zchee/deoplete-jedi/wiki/Setting-up-Python-for-Neovim). But copied into this doc for posterity:

    # Assumes fish shell
    if not test -d ~/.vim/bundle/Vundle.vim
      git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    end
    pushd ~/.vim/bundle/Vundle.vim
    git pull
    popd

    brew install pyenv pyenv-virtualenv
    pyenv install 2.7.16
    pyenv install 3.7.3

    pyenv virtualenv 2.7.16 neovim2
    pyenv virtualenv 3.7.3 neovim3

    pyenv activate neovim2
    pip install neovim
    pyenv which python  # Note the path
    pyenv deactivate

    pyenv activate neovim3
    pip install neovim
    pyenv which python  # Note the path
    # The following is optional, and the neovim3 env is still active
    # This allows flake8 to be available to linter plugins regardless
    # of what env is currently active.  Repeat this pattern for other
    # packages that provide cli programs that are used in Neovim.
    pip install flake8
    rm -f ~/bin/flake8
    ln -s (pyenv which flake8) ~/bin/flake8  # Assumes that $HOME/bin is in $PATH
    pyenv deactivate

And then my `vimrc` has the lines in it to point NeoVIM at the correct Python install. I've found it useful to run `:checkhealth` in NeoVIM after a big update or install to verify that all the components are happy and have what they need.
