# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

zmodload zsh/zprof

# Sort and source all scripts in zshrd.d
for rc in ${ZDOTDIR}/zshrc.d/*.{z,}sh(.); do
  # ignore files that begin with ~
  [[ "${rc:t}" != '~'* ]] || continue
  source "$rc"
done

# Localized configuration
if [ -f "${HOME}/.zsh_local" ]; then
  source "${HOME}/.zsh_local"
fi

# Do this almost last
autoload -Uz compinit
for dump in ${ZDOTDIR}/.zcompdump(N.mh+24); do
  compinit
done
compinit -C

# And then load this plugin
source ${ZDOTDIR:-~}/plugins/fzf-tab/fzf-tab.plugin.zsh

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/p10k.zsh.
[[ ! -f ${ZDOTDIR}/p10k.zsh ]] || source ${ZDOTDIR}/p10k.zsh

zprof
