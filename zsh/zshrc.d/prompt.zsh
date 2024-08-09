#
# prompt
#

if [[ ! -d "$ZDOTDIR/powerlevel10k" ]]; then
  git clone https://github.com/romkatv/powerlevel10k.git $ZDOTDIR/powerlevel10k
fi

source "$ZDOTDIR/powerlevel10k/powerlevel10k.zsh-theme"
