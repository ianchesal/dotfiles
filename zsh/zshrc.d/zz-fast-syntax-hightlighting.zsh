[[ -d "$ZDOTDIR/plugins/fast-syntax-highlighting" ]] ||
  git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting $ZDOTDIR/plugins/fast-syntax-highlighting
source "$ZDOTDIR/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
