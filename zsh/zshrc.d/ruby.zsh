# Use Homebrew OpenSSL on macOS; system OpenSSL on Linux.
# Homebrew's openssl@3 bottles require GLIBC_2.38+ which Debian 12 (glibc 2.36) does not have,
# causing build-time linker failures. System libssl-dev is glibc-compatible and sufficient.
if (( $+commands[brew] )); then
  if [[ "$OSTYPE" == darwin* ]]; then
    # macOS ships no OpenSSL; Homebrew's is required.
    if [[ -z "$HOMEBREW_OPENSSL_PREFIX" ]]; then
      export HOMEBREW_OPENSSL_PREFIX="$(brew --prefix openssl@3)"
    fi
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$HOMEBREW_OPENSSL_PREFIX"
  else
    # Linux: point at system OpenSSL to avoid Homebrew's glibc requirement.
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/usr"
  fi
fi

alias rake='noglob rake'                    # allows square brackts for rake task invocation
alias 'bin/rake'='noglob bin/rake'          # support use of binstub
alias brake='noglob bundle exec rake'       # execute the bundled rake gem
alias srake='noglob sudo rake'              # noglob must come before sudo
alias sbrake='noglob sudo bundle exec rake' # altogether now ...
alias be='noglob bundle exec'               # to be, or not to be...
