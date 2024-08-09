[[ -d ${ZDOTDIR:-~}/plugins/zephyr ]] ||
  git clone --depth=1 https://github.com/mattmc3/zephyr ${ZDOTDIR:-~}/plugins/zephyr

# Use zstyle to specify which plugins you want. Order matters.
zephyr_plugins=(
  completion
  compstyle
  directory
  editor
  environment
  history
  utility
  zfunctions
)
zstyle ':zephyr:load' plugins $zephyr_plugins

# Source Zephyr.
source ${ZDOTDIR:-~}/plugins/zephyr/zephyr.zsh
