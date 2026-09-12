# dotfiles/aerospace

[AeroSpace](https://github.com/nikitabobko/AeroSpace) configuration. AeroSpace is
a macOS tiling window manager built on the tree paradigm popularized by the
[i3 window manager](https://i3wm.org/). macOS-only; the config is a single TOML
file deployed to `~/.config/aerospace` via XDG.

## Layout

```
aerospace.toml    Main config: normalizations, window-detection rules, gaps, keybindings
aerospace.rake    Install/clean rake tasks
```

## Config notes

- `on-window-detected` rules auto-assign apps to workspaces (Chrome/Kitty/Terminal/Slack
  → 1, Superhuman/Linear/Fantastical → 2, Obsidian → 3) and force floating layout for
  1Password, Messages, Find My, Finder, Zoom, FaceTime, Home, Soulver, MacVirt, and
  Alfred Preferences.
- Keybindings follow i3 conventions: `alt-{j,k,l,semicolon}` to focus (wrap-around),
  `alt-shift-{h,j,k,l}` to move, `alt-{1..0}` to switch workspaces, `alt-shift-{1..0}`
  to move windows to workspaces, `alt-tab` for back-and-forth.
- `alt-shift-semicolon` enters `service` mode for resizing, config reload (`r`), and
  workspace-tree flatten (`f`).
- Configuration guide: https://nikitabobko.github.io/AeroSpace/guide

## Tasks

- `rake aerospace` — install (symlink) this config
- `rake aerospace:update` — no-op (there are no submodules in this repo)
