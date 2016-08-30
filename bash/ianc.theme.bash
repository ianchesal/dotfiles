#!/usr/bin/env bash

# Outright lifted from https://github.com/revans/bash-it
# And then customized to meet my needs.

#SCM_THEME_PROMPT_DIRTY=" ${red}✗"
SCM_THEME_PROMPT_DIRTY=" ${red}*"
#SCM_THEME_PROMPT_CLEAN=" ${bold_green}✓"
SCM_THEME_PROMPT_CLEAN="${bold_green}"
SCM_THEME_PROMPT_PREFIX="["
SCM_THEME_PROMPT_SUFFIX="${green}]"

#GIT_THEME_PROMPT_DIRTY=" ${red}✗"
GIT_THEME_PROMPT_DIRTY=" ${red}*"
#GIT_THEME_PROMPT_CLEAN=" ${bold_green}✓"
GIT_THEME_PROMPT_CLEAN="${bold_green}"
GIT_THEME_PROMPT_PREFIX="${green}[git::"
GIT_THEME_PROMPT_SUFFIX="${green}]"

RVM_THEME_PROMPT_PREFIX="|"
RVM_THEME_PROMPT_SUFFIX="|"

function prompt_command() {
    PS1="\n${reset_color}\h:${blue}\w ${green}$(scm_prompt_info)${green}${reset_color}\n>${reset_bold}${reset_color} "
}

PROMPT_COMMAND=prompt_command;
