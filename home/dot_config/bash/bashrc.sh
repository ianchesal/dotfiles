#!/usr/bin/env bash
# Sources every module in bashrc.d/ in filename order. Numeric
# prefixes control load order (env before prompt, etc.). Files
# starting with '~' are skipped, matching the zsh loader's convention
# for disabling a module without deleting it.

bashrc_dir="${HOME}/.config/bash/bashrc.d"

if [[ -d "$bashrc_dir" ]]; then
  for rc in "$bashrc_dir"/*.bash; do
    [[ -e "$rc" ]] || continue
    case "$(basename "$rc")" in
      '~'*) continue ;;
    esac
    # shellcheck disable=SC1090
    source "$rc"
  done
fi

unset bashrc_dir rc
