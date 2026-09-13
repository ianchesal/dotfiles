# Sane interactive shell options, bash 3.2 safe.
shopt -s checkwinsize
shopt -s extglob

# globstar (**/) is bash 4+ only; guard for macOS's stock bash 3.2.
if (( BASH_VERSINFO[0] >= 4 )); then
  shopt -s globstar
fi

# Match the vi keybindings used in the zsh setup.
set -o vi
