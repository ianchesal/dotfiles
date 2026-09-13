alias rm='rm -i'
alias mkdir='mkdir -p'
alias ping='ping -c 5'
alias grep='grep --color=auto'

if [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi

alias ll='ls -lAh'
alias la='ls -lAh'
alias l='ls'
