# Add fzf keybindings to my zsh sessions

# fzf via Homebrew
if [ -e /usr/local/opt/fzf/shell/completion.zsh ]; then
  source /usr/local/opt/fzf/shell/key-bindings.zsh
  source /usr/local/opt/fzf/shell/completion.zsh
fi

# fzf via local installation
if [ -e ~/.fzf ]; then
  _append_to_path ~/.fzf/bin
  # path+=(~/.fzf/bin)
  # export PATH
  source ~/.fzf/shell/key-bindings.zsh
  source ~/.fzf/shell/completion.zsh
fi

# fzf configuration
if _has fzf; then
  export FZF_DEFAULT_OPTS='
  --color info:108,prompt:109,spinner:108,pointer:168,marker:168
  --preview "[[ $(file --mime {}) =~ binary ]] &&
             echo {} is a binary file ||
             (highlight -O ansi {} ||
             cat {}) 2> /dev/null | head -$LINES"'
fi

# fzf + ripgrep configuration
if _has rg; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow -g "!{.git,node_modules}/*" 2> /dev/null'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
fi
