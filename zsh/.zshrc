#
# .zshrc
#

# zmodload zsh/zprof

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

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/p10k.zsh.
[[ ! -f ${ZDOTDIR}/p10k.zsh ]] || source ${ZDOTDIR}/p10k.zsh

# zprof
