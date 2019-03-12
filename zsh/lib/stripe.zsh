if [[ -d "$HOME/stripe" ]]; then
  autoload -U +X bashcompinit && bashcompinit
  complete -C /Users/ianc/stripe/space-commander/bin/commands/sc-complete sc
  complete -C /Users/ianc/stripe/space-commander/bin/commands/sc-complete _sc

  [ -f ~/.stripe-repos.sh ] && source ~/.stripe-repos.sh

  path+="/Users/ianc/stripe/password-vault/bin"
  path+="/Users/ianc/stripe/space-commander/bin"

  ### BEGIN HENSON
  path+="/Users/ianc/stripe/henson/bin"
  ### END HENSON

  # Useful stripe aliases and functions
  alias stripe-curl='curl -s --unix-socket ~/.stripeproxy'
  alias git=stripe-git

  function aws-credential {
    cd ~/stripe/puppet-config
    git checkout master
    git pull
    sc iam new-wizard $1
  }

  # For space-commander
  source sc-aliases

  # Go setup
  export GOPATH=${HOME}/stripe/go

  export PATH
fi
