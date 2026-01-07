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

# VHS Era Theme
# Matches https://github.com/mistweaverco/vhs-era-theme.nvim
FZF_DEFAULT_OPTS="--color=fg:#f2f4f8,bg:#161616,hl:#78a9ff"
FZF_DEFAULT_OPTS+=" --color=fg+:#f2f4f8,bg+:#353535,hl+:#82cfff"
FZF_DEFAULT_OPTS+=" --color=info:#78a9ff,prompt:#3ddbd9,pointer:#3ddbd9"
FZF_DEFAULT_OPTS+=" --color=marker:#42be65,spinner:#42be65,header:#42be65"

# Note: --tmux is ignored when not in a tmux session
FZF_DEFAULT_OPTS+=" --height 40% --tmux center"
FZF_DEFAULT_OPTS+=" --layout reverse --border"

export FZF_DEFAULT_OPTS

# fzf initialization is now handled in zvm_after_init() hook in zz-vim-mode.zsh
# This ensures fzf keybindings are restored after zsh-vi-mode loads
