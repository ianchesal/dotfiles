# Nord colors for fzf
# Generated here: https://minsw.github.io/fzf-color-picker/
#export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
#    --color=fg:#e5e9f0,bg:#3b4252,hl:#81a1c1
#    --color=fg+:#e5e9f0,bg+:#3b4252,hl+:#81a1c1
#    --color=info:#eacb8a,prompt:#bf6069,pointer:#b48dac
#    --color=marker:#a3be8b,spinner:#b48dac,header:#a3be8b'

# Molokai colors for fzf
# export FZF_DEFAULT_OPTS='
#     --color fg:252,bg:233,hl:67,fg+:252,bg+:235,hl+:81
#     --color info:144,prompt:161,spinner:135,pointer:135,marker:118'

# Tokyo Night (Dark)
# https://github.com/folke/tokyonight.nvim/issues/60
FZF_DEFAULT_OPTS="--color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7"
FZF_DEFAULT_OPTS+=" --color=fg+:#c0caf5,bg+:#1a1b26,hl+:#7dcfff"
FZF_DEFAULT_OPTS+=" --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff"
FZF_DEFAULT_OPTS+=" --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"

# Note: --tmux is ignored when not in a tmux session
FZF_DEFAULT_OPTS+=" --height 40% --tmux bottom"
FZF_DEFAULT_OPTS+=" --layout reverse --border"

export FZF_DEFAULT_OPTS

# Lazy load fzf to improve shell startup performance
# Only initialize when fzf commands are first used
if (( $+commands[fzf] )); then
  __fzf_lazy_load() {
    # Remove the lazy loading functions
    unfunction fzf __fzf_select__ __fzf_cd__ __fzf_history__ 2>/dev/null
    
    # Initialize fzf
    eval "$(fzf --zsh)"
    
    # Call the original command with all arguments
    "$1" "${@:2}"
  }
  
  # Create lazy-loading wrapper functions for common fzf commands
  fzf() { __fzf_lazy_load fzf "$@" }
  __fzf_select__() { __fzf_lazy_load __fzf_select__ "$@" }
  __fzf_cd__() { __fzf_lazy_load __fzf_cd__ "$@" }
  __fzf_history__() { __fzf_lazy_load __fzf_history__ "$@" }
fi
