# dotfiles/tmux

tmux configuration with a VHS Era theme, powerline-style status bar, and a set of
plugins managed by TPM. chezmoi **copies** `home/dot_config/tmux/` to
`~/.config/tmux`, following the XDG directory structure — so a config edit here
needs a `chezmoi apply` to go live. Portable across macOS, Debian Linux, and
WSL2.

## Layout

```
tmux.conf            Main config: plugin list, key bindings, popups, options
                     (TPM bootstrap `run '~/.config/tmux/plugins/tpm/tpm'` MUST be the last line)
theme.conf           VHS Era theme: status bar segments, pane/window styling
git-aware-popup.sh   Resolves popup dir/name from the git root (used by the `prefix g` popup)
battery.sh           Status-bar battery/UPS widget (macOS pmset, Linux NUT, no-op on WSL2)
open-url.sh          Cross-platform URL opener for tmux-fzf-url (open/wslview/xdg-open)
24-bit-color.sh      Prints a 24-bit color test ramp (just tmux::test-terminal)
plugins/             TPM (Tmux Plugin Manager) and cloned plugins, installed here under XDG
```

## Tasks

- Config is deployed by chezmoi from `home/dot_config/tmux/`; TPM is cloned by
  `home/run_once_after_55-install-tpm.sh`
- `just tmux::reload` — reload the tmux configuration for all sessions
- `just tmux::test-terminal` — print a 24-bit colour test pattern

## Notes

- Plugins: tmux-sensible, vim-tmux-navigator, tmux-yank,
  tmux-current-pane-hostname, tmux-fzf-url, tmux-fzf, tmux-scout-golang,
  tmux-jump (declared in `tmux.conf`, installed via TPM).
- Status bar uses the VHS Era palette shared with the Oh My Posh theme.
- `prefix g` opens a git-aware local popup; `prefix G` opens a global popup.
