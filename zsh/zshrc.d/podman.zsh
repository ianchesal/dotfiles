if (( $+commands[podman] )); then
  export PODMAN_IGNORE_CGROUPSV1_WARNING=1
  if [[ ! -f "${fpath[1]}/_podman" ]]; then
    podman completion -f "${fpath[1]}/_podman" zsh
  fi
fi
