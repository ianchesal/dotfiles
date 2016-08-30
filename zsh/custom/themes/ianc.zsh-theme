# Based off of frisk.zsh-theme
PROMPT=$'
%{%{$reset_color%}%M:$fg[blue]%}%~%{$reset_color%} $(git_prompt_info)$(bzr_prompt_info) %{$reset_color%}
>%{$reset_color%} '

PROMPT2="%{$fg_blod[white]%}%_> %{$reset_color%}"

GIT_CB="git::"
ZSH_THEME_SCM_PROMPT_PREFIX="%{$fg[green]%}["
ZSH_THEME_GIT_PROMPT_PREFIX=$ZSH_THEME_SCM_PROMPT_PREFIX$GIT_CB
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}*%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_RVM_PROMPT_PREFIX="%{$fg[red]%}|"
ZSH_THEME_RVM_PROMPT_SUFFIX="|%{$reset_color%}"
