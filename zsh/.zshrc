#
# .zshrc
#

# zmodload zsh/zprof

### antidote
# drive our config entirely with plugins
if [[ ! $ZDOTDIR/.zsh_plugins.zsh -nt $ZDOTDIR/.zsh_plugins.txt ]]; then
  if ! [[ -e $ZDOTDIR/.antidote ]]; then
    git clone https://github.com/mattmc3/antidote.git "$ZDOTDIR/.antidote"
  fi
  # Build ~/.zsh_plugins.txt in a subshell.
  (
    source "$ZDOTDIR/.antidote/antidote.zsh"
    antidote bundle <"$ZDOTDIR/.zsh_plugins.txt" >"$ZDOTDIR/.zsh_plugins.zsh"
  )
fi
source $ZDOTDIR/.antidote/antidote.zsh
antidote load

# Localized configuration
if [ -f "${HOME}/.zsh_local" ]; then
  source "${HOME}/.zsh_local"
fi

# Activate Powerlevel10k Instant Prompt.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# Enable the "new" completion system (compsys).
autoload -Uz compinit
compinit
if [[ ! $ZDOTDIR/.zcompdump.zwc -nt $ZDOTDIR/.zcompdump ]]; then
  zcompile -R -- $ZDOTDIR/.zcompdump.zwc $ZDOTDIR/.zcompdump
fi

ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Load plugins.
# source ~/.zsh_plugins.zsh
antidote load
# To customize prompt, run `p10k configure` or edit ~/.config/zsh/p10k.zsh.
[[ ! -f "$ZDOTDIR/p10k.zsh" ]] || source "$ZDOTDIR/p10k.zsh"

# zprof
