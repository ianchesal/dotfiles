# dotfiles/lazygit

Configuration for [lazygit](https://github.com/jesseduffield/lazygit), the
terminal UI for git. The repo's `lazygit/` directory is symlinked to
`~/.config/lazygit` following the XDG directory structure.

## Layout

```
config.yml          lazygit configuration: theme, delta pager, keybindings,
                    custom commands
```

## Notes

- Tokyo Night-ish theme with author/branch colors and a file tree view.
- Uses [delta](https://github.com/dandavison/delta) as the diff pager
  (`--dark --line-numbers --navigate`).
- Commit editing auto-wraps at 72 columns; editor preset is `nvim`.
- Auto-refreshes every 10s and auto-fetches every 60s.
- `update.method: never` — Homebrew keeps lazygit current.
- Custom keybindings: `A` amend last commit, `@` extras toggle,
  `<space>` toggle all staged.
- Custom commands:
  - `C` (files) — generate a commit message from staged diff via Claude Code
  - `E` (global) — `gh pr create --fill --assignee @me --web`
  - `R` (commits) — interactive rebase with autosquash against the main branch

## Tasks

- `rake lazygit` — install (symlink) this config
