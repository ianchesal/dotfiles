# NeoVIM

Going all in on a NeoVIM-only configuration. This straight up doesn't work in any normal vim and won't work
for a NeoVIM version less than 0.8. Living the dream.

I struggled trying to make a bespoke setup that worked. LSP was a righteous PIA to get correct. Plugins like endwise
weren't loading for me. So I'm trying out [NvChad](https://nvchad.com/) -- a bespoke setup for NeoVIM, but one that
seemed close to my thoughts on what I like to have in my vim experience, customizable, and well-maintained.

## Prerequisites

You'll want to make sure the following are on your system (and they are if you use ../brew/ and the Brewfile there to
set up your machine).

* fd
* fzf
* neovim
* tree-sitter
* ripgrep
* ruby (for the LSP support, and NeoVIM gem installed)
* python (with a neovim3 pyenv/venv created)

At some point I might write the equivalent of my ../vim/setup.sh file -- but not now.

## Setup 

Not much to it. `rake nvim` will clone NvChad in to `~/.config/nvim` and then symlink in `nvim/custom` from my dotfiles repo
to add my customizations. After you've done the setup, open `nvim` and Lazy will automatically install all the plugins.

You might need to restart `nvim` after that.

## Updating

Right now `rake nvim:update` doesn't do anything useful. You'll have to run `:NvChadUpdate` and `:TSUpdate` from your session from time to time.
