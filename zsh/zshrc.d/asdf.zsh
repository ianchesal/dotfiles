if (( $+commands[asdf] )); then
  # Find where asdf should be installed
  ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"

  # For golang compatibility
  export ASDF_GOLANG_MOD_VERSION_ENABLED=true

  if (( $+commands[brew] )); then
    brew_prefix="$(brew --prefix asdf)"
    ASDF_COMPLETIONS="${brew_prefix}/etc/bash_completion.d"
    unset brew_prefix
  fi

  path=("$ASDF_DATA_DIR/shims" "$path[@]")
fi
