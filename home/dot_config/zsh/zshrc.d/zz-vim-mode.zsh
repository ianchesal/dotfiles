# Basic vi mode setup
# (zsh-vi-mode plugin is disabled due to tab completion conflicts)
bindkey -v

# Edit command line in $EDITOR with v in normal mode
# (edit-command-line is loaded in .zshrc)
bindkey -M vicmd v edit-command-line
