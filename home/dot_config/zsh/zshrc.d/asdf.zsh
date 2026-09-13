if (( $+commands[asdf] )); then
  # Find where asdf should be installed
  ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"

  # For golang compatibility
  export ASDF_GOLANG_MOD_VERSION_ENABLED=true

  if (( $+commands[brew] )); then
    # Cache brew prefix to avoid subprocess call on every shell startup
    if [[ -z "$HOMEBREW_ASDF_PREFIX" ]]; then
      export HOMEBREW_ASDF_PREFIX="$(brew --prefix asdf)"
    fi
    ASDF_COMPLETIONS="${HOMEBREW_ASDF_PREFIX}/etc/bash_completion.d"
  fi

  path=("$ASDF_DATA_DIR/shims" "$path[@]")
fi
