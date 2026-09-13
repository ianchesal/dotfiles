#
# environment
#

### variables
SHELL_SESSIONS_DISABLE=1
KEYTIMEOUT=1

if (( $+commands[nvim] )); then
  export EDITOR="nvim"
  export VISUAL="nvim"
else
  export EDITOR="vim"
  export VISUAL="vim"
fi

# export GREP_COLOR='1;32'
# export GREP_COLORS='mt=1;32'
export LSCOLOR="Gxfxcxdxbxegedabagacad"

# For Terminal.app
export CLICOLOR=1

# I forget what this does...
export COPYFILE_DISABLE=true

# My bin directory
path+="$HOME/bin"

# XDG bin directory
if [[ -d "$HOME/.local/bin" ]]; then
    path+="$HOME/.local/bin"
fi

typeset -gU path

# History
HISTSIZE=100000
HISTFILE="${XDG_DATA_HOME:-${HOME}/.local/share}/zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
