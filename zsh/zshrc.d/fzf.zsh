[[ -d ${ZDOTDIR:-~}/plugins/fzf-zsh-plugin ]] ||
  git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZDOTDIR:-~}/plugins/fzf-zsh-plugin
source ${ZDOTDIR:-~}/plugins/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh

[[ -d ${ZDOTDIR:-~}/plugins/fzf-tab ]] ||
  git clone --depth=1 https://github.com/Aloxaf/fzf-tab ${ZDOTDIR:-~}/plugins/fzf-tab
# https://github.com/Aloxaf/fzf-tab?tab=readme-ov-file#install
# source ${ZDOTDIR:-~}/plugins/fzf-tab/fzf-tab.plugin.zsh

[[ -d ${ZDOTDIR:-~}/plugins/fzf-tab-source ]] ||
  git clone --depth=1 https://github.com/Freed-Wu/fzf-tab-source ${ZDOTDIR:-~}/plugins/fzf-tab-source
source ${ZDOTDIR:-~}/plugins/fzf-tab-source/fzf-tab-source.plugin.zsh

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
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' 
	--color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
	--color=fg+:#c0caf5,bg+:#1a1b26,hl+:#7dcfff
	--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff 
	--color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a'
