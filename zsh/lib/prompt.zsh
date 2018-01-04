#ICO_DIRTY="⚡"
#ICO_DIRTY="↯"
ICO_DIRTY="*"
#ICO_AHEAD="↑"
ICO_AHEAD="🠙"
#ICO_AHEAD="▲"
#ICO_BEHIND="↓"
ICO_BEHIND="🠛"
#ICO_BEHIND="▼"
ICO_DIVERGED="⥮"
PROMPT_STYLE="classic"


# A fast branch display in the prompt
# See: https://stackoverflow.com/a/1128583/259811
setopt prompt_subst
autoload -Uz colors && colors
autoload -Uz vcs_info
zstyle ':vcs_info:*' actionformats "%{$fg[green]%}[%s::%b|%a]"
zstyle ':vcs_info:*' formats "%{$fg[green]%}[%s::%b]"
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat "%b%F{1}:%F{3}%r"

zstyle ':vcs_info:*' enable git

# or use pre_cmd, see man zshcontrib
vcs_info_wrapper() {
  vcs_info
  if [ -n "$vcs_info_msg_0_" ]; then
    echo "%{$fg[grey]%}${vcs_info_msg_0_}%{$reset_color%}$del"
  fi
}
# Put the SCC info on the right side of the screen
# RPROMPT=$'$(vcs_info_wrapper)'

# Based off of frisk.zsh-theme
PROMPT=$'
%{%{$reset_color%}%M:%{$fg[blue]%}%}%~%{$reset_color%} $(vcs_info_wrapper) %{$reset_color%}
>%{$reset_color%} '

PROMPT2="%{$fg_blod[white]%}%_> %{$reset_color%}"

