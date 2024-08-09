#
# prompt
#

[[ -d "$ZDOTDIR/plugins/powerlevel10k" ]] ||
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZDOTDIR/plugins/powerlevel10k

source "$ZDOTDIR/plugins/powerlevel10k/powerlevel10k.zsh-theme"
