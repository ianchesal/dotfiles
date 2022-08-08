#
# aliases
#

# suffix aliases (ie: `cd ..4`)
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep -E'
alias -g S='| sort'
alias -g L='| less'
alias -g M='| more'
alias -g ..2='../..'
alias -g ..3='../../..'
alias -g ..4='../../../..'
alias -g ..5='../../../../..'
alias -g ..6='../../../../../..'
alias -g ..7='../../../../../../..'
alias -g ..8='../../../../../../../..'
alias -g ..9='../../../../../../../../..'
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

# single character shortcuts - be sparing!
#alias _=sudo
#alias d='dirs -v'
#alias l=ls

# mask built-ins with better defaults
#alias cp='cp -i'
#alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -p'
alias ping='ping -c 5'
alias type='type -a'
alias vi=vim
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls="ls -G"
else
  alias ls="ls --color=auto"
fi
alias grep="grep --color=auto --exclude-dir={CVS,.git,.hg,.svn}"

# more ways to ls
alias ll='ls -lah'
alias la='ls -lAh'
alias ldot='ls -ld .*'

# fix typos
#alias quit='exit'
alias cd..='cd ..'

# tar
alias tarls="tar -tvf"
alias untar="tar -xf"

# date/time
alias timestamp="date '+%Y-%m-%d %H:%M:%S'"
alias datestamp="date '+%Y-%m-%d'"

# find
#alias fd='find . -type d -name'
#alias ff='find . -type f -name'

# disk usage
alias biggest='du -s ./* | sort -nr | awk '\''{print $2}'\'' | xargs du -sh'
alias dux='du -x --max-depth=1 | sort -n'
alias dud='du -d 1 -h'
alias duf='du -sh *'

# url encode/decode
alias urldecode='python3 -c "import sys, urllib.parse as ul; \
    print(ul.unquote_plus(sys.argv[1]))"'
alias urlencode='python3 -c "import sys, urllib.parse as ul; \
    print (ul.quote_plus(sys.argv[1]))"'

# history
# list the ten most used commands
alias history-stat="history 0 | awk '{print \$2}' | sort | uniq -c | sort -n -r | head"
alias history="fc -li"

# misc
alias please=sudo
alias zshrc='${EDITOR:-vim} "${ZDOTDIR:-$HOME}"/.zshrc'
alias zshrcd='${EDITOR:-vim} "${ZDOTDIR:-$HOME}"/zshrc.d'
alias zbench='for i in {1..10}; do /usr/bin/time zsh -lic exit; done'
alias zdot='cd $ZDOTDIR'


# FROM MY OLD zshrc FILE !!!
#alias emacs="vim"
alias please='sudo $(fc -ln -1)'
alias gau='git add -u'
alias gci='git commit --verbose'
alias gcis='git commit --gpg-sign --verbose'
alias gd='git diff --color=always'
alias gpfoh='git push --force origin HEAD'
alias gpoh='git push origin HEAD'
alias grep='grep --color=auto -E'
alias gri='git rebase -i'
alias gss='git status --short --branch'
alias rsync-copy="rsync -avz --progress -h"
alias rsync-move="rsync -avz --progress -h --remove-source-files"
alias rsync-synchronize="rsync -avzu --delete --progress -h"
alias rsync-update="rsync -avzu --progress -h"
if _has nvim; then
  alias vim=nvim
fi
#alias vim-update-plugins='vim +PlugUpdate +qall'
alias ta='tmux attach -t'
alias tad='tmux attach -d -t'
alias ts='tmux new-session -s'
alias tl='tmux list-sessions'
alias tksv='tmux kill-server'
alias tkss='tmux kill-session -t'

# Curl Power Ups
alias hstat="curl -o /dev/null --silent --head --write-out '%{http_code}\n'" $1
