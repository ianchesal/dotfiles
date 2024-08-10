[[ -d ${ZDOTDIR:-~}/plugins/fzf-zsh-plugin ]] ||
  git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZDOTDIR:-~}/plugins/fzf-zsh-plugin
source ${ZDOTDIR:-~}/plugins/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh

[[ -d ${ZDOTDIR:-~}/plugins/fzf-tab ]] ||
  git clone --depth=1 https://github.com/Aloxaf/fzf-tab ${ZDOTDIR:-~}/plugins/fzf-tab
# https://github.com/Aloxaf/fzf-tab?tab=readme-ov-file#install
# source ${ZDOTDIR:-~}/plugins/fzf-tab/fzf-tab.plugin.zsh

[[ -d ${ZDOTDIR:-~}/plugins/fzf-tab-source ]] ||
  git clone --depth=1 https://github.com/Freed-Wu/fzf-tab-source ${ZDOTDIR:-~}/plugins/fzf-tab-source
source ${ZDOTDIR:-~}/plugins/fzf-tab-source/fzf-tab-source.plugin.zsh

# Nord colors for fzf
# Generated here: https://minsw.github.io/fzf-color-picker/
#export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
#    --color=fg:#e5e9f0,bg:#3b4252,hl:#81a1c1
#    --color=fg+:#e5e9f0,bg+:#3b4252,hl+:#81a1c1
#    --color=info:#eacb8a,prompt:#bf6069,pointer:#b48dac
#    --color=marker:#a3be8b,spinner:#b48dac,header:#a3be8b'
# Molokai colors for fzf
export FZF_DEFAULT_OPTS='
    --color fg:252,bg:233,hl:67,fg+:252,bg+:235,hl+:81
    --color info:144,prompt:161,spinner:135,pointer:135,marker:118'

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fe() {
  local files
  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR:-nvim} "${files[@]}"
}

# Modified version where you can press
#   - CTRL-O to open with `open` command,
#   - CTRL-E or Enter key to open with the $EDITOR
fo() {
  local out file key
  IFS=$'\n' out=("$(fzf-tmux --query="$1" --exit-0 --expect=ctrl-o,ctrl-e)")
  key=$(head -1 <<<"$out")
  file=$(head -2 <<<"$out" | tail -1)
  if [ -n "$file" ]; then
    [ "$key" = ctrl-o ] && open "$file" || ${EDITOR:-nvim} "$file"
  fi
}

# cdf - cd into the directory of the selected file
cdf() {
  local file
  local dir
  file=$(fzf +m -q "$1") && dir=$(dirname "$file") && cd "$dir"
}

# fkill - kill processes - list only the ones you can kill. Modified the earlier script.
# fkill() {
#   local pid
#   if [ "$UID" != "0" ]; then
#       pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
#   else
#       pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
#   fi
#
#   if [ "x$pid" != "x" ]
#   then
#       echo $pid | xargs kill -${1:-9}
#   fi
# }

# tm - create new tmux session, or switch to existing one. Works from within tmux too. (@bag-man)
# `tm` will allow you to select your tmux session via fzf.
# `tm irc` will attach to the irc session (if it exists), else it will create it.
tm() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ $1 ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1")
    return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) && tmux $change -t "$session" || echo "No sessions found."
}

# List all vagrant boxes available in the system including its
# status, and try to access the selected one via ssh
vs() {
  cd $(cat ~/.vagrant.d/data/machine-index/index | jq '.machines[] | {name, vagrantfile_path, state}' | jq '.name + "," + .state  + "," + .vagrantfile_path' | sed 's/^"\(.*\)"$/\1/' | column -s, -t | sort -rk 2 | fzf | awk '{print $3}')
  vagrant ssh
}

# fh - repeat history
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}
