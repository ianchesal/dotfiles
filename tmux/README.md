# dotfiles/tmux

tmux configuration with a VHS Era theme, powerline-style status bar, and a set of
plugins managed by TPM. Deployed to `~/.config/tmux` following the XDG directory
structure (the repo's `tmux/` dir is symlinked there). Portable across macOS,
Debian Linux, and WSL2.

## Layout

```
tmux.conf            Main config: plugin list, key bindings, popups, options
                     (TPM bootstrap `run '~/.config/tmux/plugins/tpm/tpm'` MUST be the last line)
theme.conf           VHS Era theme: status bar segments, pane/window styling
git-aware-popup.sh   Resolves popup dir/name from the git root (used by the `prefix g` popup)
battery.sh           Status-bar battery/UPS widget (macOS pmset, Linux NUT, no-op on WSL2)
open-url.sh          Cross-platform URL opener for tmux-fzf-url (open/wslview/xdg-open)
24-bit-color.sh      Prints a 24-bit color test ramp (rake tmux:testterminal)
plugins/             TPM (Tmux Plugin Manager) and cloned plugins, installed here under XDG
```

## Tasks

- `rake tmux` — install (symlink) the config and clone TPM
- `rake tmux:reload` — reload the tmux configuration for all sessions
- `rake clean` — remove the config symlink and tmux state/cache dirs

## Notes

- Plugins: tmux-sensible, vim-tmux-navigator, tmux-yank,
  tmux-current-pane-hostname, tmux-fzf-url, tmux-fzf, tmux-scout-golang,
  tmux-jump (declared in `tmux.conf`, installed via TPM).
- Status bar uses the VHS Era palette shared with the Oh My Posh theme.
- `prefix g` opens a git-aware local popup; `prefix G` opens a global popup.
