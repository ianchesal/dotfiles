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

# To customize prompt, run `p10k configure` or edit ~/.zsh/.p10k.zsh.
[[ ! -f ~/.zsh/.p10k.zsh ]] || source ~/.zsh/.p10k.zsh

# Localized configuration
if [ -f "${HOME}/.zsh_local" ]; then
  source "${HOME}/.zsh_local"
fi

# zprof

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/p10k.zsh.
[[ ! -f ~/.config/zsh/p10k.zsh ]] || source ~/.config/zsh/p10k.zsh
