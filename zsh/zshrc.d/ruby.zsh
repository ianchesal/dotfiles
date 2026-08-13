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
    #
    # --without-gmp for the same reason: ruby-build auto-detects Homebrew's gmp and
    # passes --with-gmp-dir, which puts -lgmp in SOLIBS. mkmf then builds its conftest
    # link line for the bundled extensions (zlib, stringio, bigdecimal, fiddle, ...)
    # from SOLIBS plus CONFIGURE_ARGS below, which carries no -L for Homebrew's lib
    # dir -- and Debian has no libgmp.so without libgmp-dev, so -lgmp cannot resolve
    # and every bundled extension silently fails to configure. gmp only accelerates
    # Bignum arithmetic, so dropping it is cheaper than coupling Ruby to a versioned
    # Cellar path that breaks on the next `brew upgrade gmp`.
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/usr --without-gmp"

    # linuxbrew's ld (binutils formula) precedes the system ld on PATH but
    # doesn't search Debian's multiarch lib dir, so it can't resolve
    # libcrypt.so.1 (a transitive dependency of libruby.so) when native gem
    # extensions link against libruby. -rpath-link (not -L) is what GNU ld
    # actually consults to resolve a shared library's own indirect
    # dependencies. mkmf reads CONFIGURE_ARGS out of the environment, so this
    # covers bundler-driven builds and Mason's plain `gem install` calls alike
    # -- do NOT mirror it into a committed .bundle/config, which has no way to
    # express "Linux only" and would break native builds on macOS.
    export CONFIGURE_ARGS="--with-ldflags=-Wl,-rpath-link,/usr/lib/x86_64-linux-gnu"
  fi
fi

alias rake='noglob rake'                    # allows square brackts for rake task invocation
alias 'bin/rake'='noglob bin/rake'          # support use of binstub
alias brake='noglob bundle exec rake'       # execute the bundled rake gem
alias srake='noglob sudo rake'              # noglob must come before sudo
alias sbrake='noglob sudo bundle exec rake' # altogether now ...
alias be='noglob bundle exec'               # to be, or not to be...
