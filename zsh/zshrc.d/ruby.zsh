# Use Homebrew dependencies w/Ruby
if (( $+commands[brew] )); then
  # Cache brew prefixes to avoid subprocess calls on every shell startup
  if [[ $(hostname) == "fractal-vbox" ]]; then
    if [[ -z "$HOMEBREW_RUBY_CONFIGURE_OPTS" ]]; then
      export HOMEBREW_RUBY_CONFIGURE_OPTS="--with-zlib-dir=$(brew --prefix zlib) --with-openssl-dir=$(brew --prefix openssl@3) --with-readline-dir=$(brew --prefix readline) --with-libyaml-dir=$(brew --prefix libyaml)"
    fi
    export RUBY_CONFIGURE_OPTS="$HOMEBREW_RUBY_CONFIGURE_OPTS"
  else
    if [[ -z "$HOMEBREW_OPENSSL_PREFIX" ]]; then
      export HOMEBREW_OPENSSL_PREFIX="$(brew --prefix openssl)"
    fi
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$HOMEBREW_OPENSSL_PREFIX"
  fi
fi

alias rake='noglob rake'                    # allows square brackts for rake task invocation
alias 'bin/rake'='noglob bin/rake'          # support use of binstub
alias brake='noglob bundle exec rake'       # execute the bundled rake gem
alias srake='noglob sudo rake'              # noglob must come before sudo
alias sbrake='noglob sudo bundle exec rake' # altogether now ...
alias be='noglob bundle exec'               # to be, or not to be...
