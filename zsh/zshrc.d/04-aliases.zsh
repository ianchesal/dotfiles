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
alias v=vim
alias vi=vim
# alias v=vim
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls="ls -G"
else
  alias ls="ls --color=auto"
fi
# alias grep="grep --color=auto --exclude-dir={CVS,.git,.hg,.svn}"

# more ways to ls
alias l=ls
alias ll='ls -lAh'
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

# tmux
# alias tmux='TERM=screen-256color tmux -2' # Makes Terminal.app work

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

# fzf stuff
alias fe='fzf-find-edit'

# git
alias forgit-help='echo "Forgit Commands:\n  ga   - git add selector\n  glo  - git log browser\n  gi   - .gitignore generator\n  gd   - git diff viewer\n  grh  - git reset HEAD selector\n  gcf  - git checkout file selector\n  gclean - git clean selector\n  gsv  - git stash viewer\n  gcp  - git cherry-pick selector\n  grb  - git rebase selector"'
alias unfuck-mutagen='git clean -df'
alias gap='git add -p'
alias gau='git add -u'
alias gb='git branch'
alias gbD='git branch -D'
alias gbd='git branch -d'
alias gci='git commit --verbose'
alias gcis='git commit --gpg-sign --verbose'
alias gco='git checkout'
alias gcob='git switch -c'
alias gcom='git com'
# alias gd='git diff --color=always'  # Commented to use forgit's interactive git diff instead
alias gfu='git fixup'
alias gl='git log --color=always'
alias gll='git log --color=always | less -r'
alias glsut='git ls-files --others --exclude-standard'
alias gp='git pull'
alias gpfoh='git push --force-with-lease origin HEAD'
alias gpoh='git push origin HEAD'
alias gri='git rebase --interactive'
alias grim='git rebase --interactive --autosquash $(git main-branch)'
alias gsp='git stash push -u'
alias gss='git status --short --branch'
alias gsv='forgit::stash::show'  # forgit interactive stash viewer

# github
alias ghpca='gh pr create --fill --label auto-assign-reviewers --assignee @me'
alias ghpci='gh pr create --fill --assignee @me --reviewer persona-id/infrastructure'
alias ghpcic='gh pr create --fill --assignee @me --label claude --reviewer persona-id/infrastructure'

# misc
alias please='sudo $(fc -ln -1)'

# rsync
alias rsync-copy="rsync -avz --progress -h"
alias rsync-move="rsync -avz --progress -h --remove-source-files"
alias rsync-synchronize="rsync -avzu --delete --progress -h"
alias rsync-update="rsync -avzu --progress -h"
if (( $+commands[nvim] )); then
  alias vim=nvim
fi

# tmux
alias tl='tmux list-sessions'

# Curl Power Ups
alias hstat="curl -o /dev/null --silent --head --write-out '%{http_code}\n'" $1
alias myip="curl -s http://whatismyip.akamai.com/"
alias curl-test-site="curl --silent --show-error --dump-header - $1 -o /dev/null"

alias pstree='ps -auxwf'

# Terraform
alias tf='terraform'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tff='terraform fmt'
alias tfi='terraform init'
alias tfo='terraform output'
alias tfp='terraform plan'
alias tfpl='terraform providers lock -platform=darwin_arm64 -platform=linux_amd64'
alias tfv='terraform validate'

# Docker/Podman compatibility
if (( $+commands[podman] )); then
  alias docker=podman
fi

# Dotfiles
alias dfu=dotfiles_update

# Serena MCP Server
alias serena='uv run --directory ~/src/dotfiles/serena/.serena serena-mcp-server --project .'
alias serena-add-mcp='claude mcp add serena -- uv "run" --directory ~/src/dotfiles/serena/.serena serena-mcp-server --project . --context ide-assistant --enable-web-dashboard False'
