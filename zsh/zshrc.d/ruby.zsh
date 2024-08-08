# Use Homebrew OpenSSL w/Ruby
if type brew >/dev/null; then
  export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl)"
fi
alias rake='noglob rake'                    # allows square brackts for rake task invocation
alias 'bin/rake'='noglob bin/rake'          # support use of binstub
alias brake='noglob bundle exec rake'       # execute the bundled rake gem
alias srake='noglob sudo rake'              # noglob must come before sudo
alias sbrake='noglob sudo bundle exec rake' # altogether now ...
alias be='noglob bundle exec'               # to be, or not to be...
