autoload -Uz compinit
compinit
autoload -U ~/Development/dotfiles/zsh/lib/completion/*(:t)

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
if _has dircolors; then
  # eval "$(dircolors -b)"
  zstyle ':completion:*' menu select=2 eval "$(dircolors -b)"
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
  alias ls='ls --color'
else
  export CLICOLOR=1
  zstyle ':completion:*:default' list-colors ''
fi
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# use graphical menu for tab completion
zstyle ':completion:*:*:*:*:*' menu select

# completion options
setopt auto_menu                 # show completion menu on succesive tab press
setopt menu_complete             # toggle auto-selecting first menu entry (overrides auto_menu)
setopt always_last_prompt        # second tab replaces first suggestions instead of reprinting new prompt
setopt list_types                # append types of files in tab-completion menu (like ls -F)
unsetopt list_rows_first         # list files by columns, not rows in tab-completion menu
setopt complete_in_word          # allow completion inside word instead of putting cursor to end of word
setopt always_to_end             # when completing inside word, move cursor to end after full completion is inserted
