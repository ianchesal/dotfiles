#
# .zshrc
#

# zmodload zsh/zprof

### antidote
# drive our config entirely with plugins
if ! [[ -e $ZDOTDIR/.antidote ]]
then
  git clone https://github.com/mattmc3/antidote.git $ZDOTDIR/.antidote
fi
source $ZDOTDIR/.antidote/antidote.zsh
antidote load

# Localized configuration
if [ -f "${HOME}/.zsh_local" ]; then
  source "${HOME}/.zsh_local"
fi

# Starship prompt
eval "$(starship init zsh)"

# zprof
