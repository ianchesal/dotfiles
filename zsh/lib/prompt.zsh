# Load the pure prompt from my dotfiles
fpath=( $HOME/code/dotfiles/zsh/pure $fpath )
autoload -U promptinit
promptinit
prompt pure
