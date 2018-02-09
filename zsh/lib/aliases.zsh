alias atom-update-packages="cd ~/Development/dotfiles; rake atom:packages"
alias atom-update-plugins=atom-update-packages
alias atom="/Applications/Atom.app/Contents/Resources/app/atom.sh"
alias be='bundle exec'
alias ber='bundle exec ruby'
alias brails='bundle exec rails'
alias brake='noglob bundle exec rake' # execute the bundled rake gem
alias emacs="vim"
alias fuck='sudo $(fc -ln -1)'
alias gci='git commit --verbose'
alias gd='git diff --color=always'
alias gdl='git diff --color=always | less -r'
alias gll='git log --color=always | less -r'
alias gpoh='git push origin HEAD'
alias grep='grep --color=auto -E'
alias gss='git status --short --branch'
alias ll='ls -lah'
alias rake="noglob rake" # allows square brackts for rake task invocation
alias rsync-copy="rsync -avz --progress -h"
alias rsync-move="rsync -avz --progress -h --remove-source-files"
alias rsync-synchronize="rsync -avzu --delete --progress -h"
alias rsync-update="rsync -avzu --progress -h"
alias sbrake='noglob sudo bundle exec rake' # altogether now ... 
alias srake='noglob sudo rake' # noglob must come before sudo
alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"
alias tree='tree -CAFa -I "CVS|*.*.package|.svn|.git|.hg|node_modules|bower_components" --dirsfirst'
alias v="vim"
alias v='vim'
alias vi="vim"
alias vim-update-plugins='vim +PluginInstall +qall'

function rgp {
  rg -p $* | less -R
}
