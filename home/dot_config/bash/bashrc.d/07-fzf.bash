if command -v fzf >/dev/null 2>&1; then
  # fzf >= 0.48 ships its own shell-integration flag.
  if fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
  else
    # Older fzf: source the standalone key-bindings/completion pair
    # from wherever the install put them.
    for fzf_dir in \
      "$(command -v brew >/dev/null 2>&1 && echo "$(brew --prefix)/opt/fzf/shell")" \
      /usr/share/doc/fzf/examples \
      /usr/share/fzf; do
      [[ -n "$fzf_dir" && -d "$fzf_dir" ]] || continue
      fzf_found=0
      [[ -f "$fzf_dir/key-bindings.bash" ]] && { source "$fzf_dir/key-bindings.bash"; fzf_found=1; }
      [[ -f "$fzf_dir/completion.bash" ]] && { source "$fzf_dir/completion.bash"; fzf_found=1; }
      [[ $fzf_found -eq 1 ]] && break
    done
    unset fzf_dir fzf_found
  fi
fi
