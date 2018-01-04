# Paths
export PATH="/usr/local/sbin:/usr/local/bin:${PATH}"

# Python configuration
export WORKON_HOME=$HOME/.virtualenvs
export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python2

# Preferred editor for local and remote sessions
# (Yes, I know it's vim in both cases...)
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

export GREP_COLOR='1;32'

export LSCOLOR="Gxfxcxdxbxegedabagacad"

export JAVA_HOME="$(/usr/libexec/java_home)"

if [[ -d "${HOME}/.aws/certs" ]]; then
  export EC2_PRIVATE_KEY="$(/bin/ls "$HOME"/.aws/certs/*-pk.pem | /usr/bin/head -1)"
  export EC2_CERT="$(/bin/ls "$HOME"/.aws/certs/*-cert.pem | /usr/bin/head -1)"
fi
export EC2_HOME="/usr/local/Cellar/ec2-api-tools/1.7.1.0/libexec"

[[ -s "$HOME/.aws/keys.zsh" ]] && source "$HOME/.aws/keys.zsh"

export COPYFILE_DISABLE=true

# automatically enter directories without cd
setopt auto_cd

# Language
export LC_COLLATE=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8
export LC_MONETARY=en_US.UTF-8
export LC_NUMERIC=en_US.UTF-8
export LC_TIME=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LESSCHARSET=utf-8