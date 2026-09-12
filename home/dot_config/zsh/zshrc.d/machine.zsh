#
# machine identity
#
# Exports DOTFILES_MACHINE so the prompt (ohmyposh/ohmyposh.json) can tell this
# Google Cloud Workstation apart from the Mac and WSL2 boxes.
#
# Detector: /etc/workstation-startup.d is created by the Cloud Workstations
# image. A [ -d ] test cannot depend on the environment, so it behaves the same
# from a detached shell. The tmux side runs the identical test via if-shell in
# tmux/tmux.conf -- keep the two in sync.
#
# Pre-set DOTFILES_MACHINE to override, e.g. to preview the marker elsewhere:
#   DOTFILES_MACHINE=gcw exec zsh

# Work machine flag: ~/.work_machine is the source of truth (touch to enable, rm
# to disable). WORK_MACHINE is exported from it for anything outside this repo
# that still reads the variable -- repo code tests the file, never the export,
# so it keeps working in tmux popups, cron and other detached contexts.
if [[ -f "${HOME}/.work_machine" ]]; then
  export WORK_MACHINE=true
fi

if [[ -z "${DOTFILES_MACHINE:-}" ]]; then
  if [[ -d /etc/workstation-startup.d ]]; then
    DOTFILES_MACHINE=gcw
  else
    DOTFILES_MACHINE=other
  fi
fi
export DOTFILES_MACHINE
