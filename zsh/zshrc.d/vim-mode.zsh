[[ -d ${ZDOTDIR:-~}/plugins/zsh-vim-mode ]] ||
  git clone --depth=1 https://github.com/softmoth/zsh-vim-mode.git ${ZDOTDIR:-~}/plugins/zsh-vim-mode
source ${ZDOTDIR:-~}/plugins/zsh-vim-mode/zsh-vim-mode.plugin.zsh
