# dotfiles

[![CI](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml)

[![forthebadge](https://forthebadge.com/images/badges/0-percent-optimized.svg)](https://forthebadge.com)

My dotfiles. What else were you expecting?

## Use

    mkdir -p ~/src
    pushd ~/src
    git clone git@github.com:ianchesal/dotfiles.git
    cd dotfiles
    rake all

You can link up some of the bits and pieces using the included `Rakefile`. See:

    rake -T

for the targets you can run to link up pieces. Not everything is available for
automatic installation via the `Rakefile`.
