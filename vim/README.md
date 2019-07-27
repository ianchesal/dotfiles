# Using Python with NeoVIM

I've simplified all of this down to a shell script. Run:

    cd ~/code/dotfiles
    ./vim/setup.sh

and it will run all the virtualenv setup that needs to be run for pyenv, rbenv and node.

## Troubleshooting

* From within `neovim` you can run `:checkhealth` to see what it thinks your environment is
* If `pyenv` fails to install a python try reinstalling the CLI tools for your XCode version from [here](https://developer.apple.com/download/more/?=command%20line%20tools)
