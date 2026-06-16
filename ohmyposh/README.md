# dotfiles/ohmyposh

[Oh My Posh](https://ohmyposh.dev/) prompt configuration: a custom VHS Era theme
with a defined color palette, rendered as left/right/newline prompt blocks. Shows
path (powerlevel style), git branch and ahead/behind/stash status, command
execution time, and a command-status indicator, with tooltips for AWS, GCP, and
kubectl. Deployed to `~/.config/ohmyposh` (the repo dir is symlinked there).

## Layout

```
ohmyposh.json       Main config: VHS Era palette, prompt blocks, git segment, tooltips
claude.json         Slim prompt variant adding a Claude segment (model + token gauge + cost)
ohmyposh.json.bak   Backup of a prior config
```

## Tasks

- `rake ohmyposh` — install (symlink) this config to `~/.config/ohmyposh`
- `rake ohmyposh:check_update` — check for an Oh My Posh update via Homebrew
- `rake ohmyposh:update` — update Oh My Posh via `brew upgrade` + `brew cleanup`
- `rake ohmyposh:clean` — remove the `~/.config/ohmyposh` symlink

## Notes

- Oh My Posh is managed via Homebrew; the update tasks no-op when `brew` is absent.
- The VHS Era palette (`main-bg` `#161616`, `terminal-blue` `#78a9ff`, etc.) is
  shared with the tmux status bar theme.
