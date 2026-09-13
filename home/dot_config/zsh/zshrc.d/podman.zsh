if (( $+commands[podman] )); then
  export PODMAN_IGNORE_CGROUPSV1_WARNING=1
  
  # Optimize completion loading with background regeneration (like kubernetes)
  if [[ ! -f "${fpath[1]}/_podman" ]]; then
    # If completion file doesn't exist, generate it synchronously
    podman completion zsh > "${fpath[1]}/_podman"
  else
    # If it exists, regenerate in background to keep it current
    podman completion zsh > "${fpath[1]}/_podman" &|
  fi
fi
