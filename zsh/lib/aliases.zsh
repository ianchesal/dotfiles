alias atom-update-packages="cd ~/code/dotfiles; rake atom:packages"
alias atom-update-plugins=atom-update-packages
alias atom="/Applications/Atom.app/Contents/Resources/app/atom.sh"
alias be='bundle exec'
alias ber='bundle exec ruby'
alias emacs="vim"
alias please='sudo $(fc -ln -1)'
alias gci='git commit --verbose'
alias gcis='git commit --gpg-sign --verbose'
alias gd='git diff --color=always'
alias gdl='git diff --color=always | less -r'
alias gll='git log --color=always | less -r'
alias gpoh='git push origin HEAD'
alias grep='grep --color=auto -E'
alias gss='git status --short --branch'
alias irc-server='gcloud compute ssh ian@irc-client'
alias ll='ls -lah'
alias rsync-copy="rsync -avz --progress -h"
alias rsync-move="rsync -avz --progress -h --remove-source-files"
alias rsync-synchronize="rsync -avzu --delete --progress -h"
alias rsync-update="rsync -avzu --progress -h"
alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"
alias v="vim"
alias v='vim'
alias vi="vim"
alias vim-update-plugins='vim +PluginInstall +qall'

# Curl Power Ups
alias hstat="curl -o /dev/null --silent --head --write-out '%{http_code}\n'" $1

# Unalias stuff that gets set in oh-my-zsh plugins
unalias gom
