# dotfiles/ohmyposh

[Oh My Posh](https://ohmyposh.dev/) prompt configuration: a custom VHS Era theme
with a defined color palette, drawn as plain colored text over two lines. chezmoi
copies `home/dot_config/ohmyposh/` to `~/.config/ohmyposh`.

## What the prompt shows

- `user@host` only over SSH or on the cloud workstation (with a lime `GCW`
  badge, which also recolors the prompt). Root shells don't run oh-my-posh at
  all, by design: they stay plain so a broken prompt can't lock you out
- Outside a git repo, the path in powerlevel style: shown in full up to 40
  columns, abbreviated from the left past that, always with the leading `/`
- Inside a repo, the repo name plus the path below its root (`dotfiles/home/dot_config`),
  trimmed to the last two folders when long, then the branch. The git segment
  draws this itself and the path segment stays quiet: the path segment checks
  `.Segments.Contains "Git"`, which only sees segments already drawn, so git
  must stay ahead of path in the block
- Branch markers: `~` staged, `*` unstaged, `↑N↓N` ahead/behind, `$N` stashes,
  `worktree` in a linked worktree. Rebase/merge/cherry-pick/revert turn the
  branch red and name the operation
- Right side: execution time past 2s, then `rb`/`node`/`go`/`py` versions, each
  only in a directory holding that language's files
- `✗ <code> >` after a failed command
- Tooltips for AWS, GCP, and kubectl

## Layout

```
ohmyposh.json       Main config: VHS Era palette, prompt blocks, tooltips
claude.json         Slim variant for the Claude Code status line (model + token gauge + cost)
```

## Tasks

- Config is deployed by chezmoi from `home/dot_config/ohmyposh/`
- `just ohmyposh::preview` — render the repo's config across a fixed set of
  situations (paths, dirty/ahead/rebasing/worktree repos, failed and slow
  commands, ssh, cloud workstation) using throwaway git repos
- `just ohmyposh::check-update` — check for an Oh My Posh update via Homebrew
- `just ohmyposh::update` — update Oh My Posh via `brew upgrade` + `brew cleanup`

## Notes

- **Use `just ohmyposh::preview` to check an edit, not a live shell.** oh-my-posh
  caches the config per shell session, so an open shell keeps drawing the old
  prompt after an edit (`exec zsh` picks up the new one). And chezmoi copies the
  config, so `~/.config/ohmyposh` lags the repo until `chezmoi apply`. The preview
  renders the repo's copy with a fresh session every time.
- Oh My Posh is managed via Homebrew; the update tasks no-op when `brew` is absent.
- The VHS Era palette (`main-bg` `#161616`, `terminal-blue` `#78a9ff`, etc.) is
  shared with the tmux status bar theme.
