# dotfiles/kitty

[Kitty](https://sw.kovidgoyal.net/kitty/) terminal configuration. The main
config is organized with fold markers (`#: ... {{{`) for sections and pulls in
the active color theme via an `include` line. Currently includes
`tokyonight_night.conf`.

## Layout

```
kitty.conf                Main configuration (fonts, keys, tabs, etc.)
*.conf                    Color themes kept at top level (dracula, molokai,
                          nord, onedark, gruvbox_*, gotham, borland, rxyhn,
                          tokyonight_night, diff)
themes/                   The upstream kitty-themes collection (~170 .conf files)
macos-launch-services-cmdline   macOS launch-services arguments
kitty.rake                Install/clean tasks
```

To switch themes, change the `include ./<theme>.conf` line near the bottom of
`kitty.conf`.

## Tasks

- `rake kitty` — install kitty terminal configuration (symlink this dir to `~/.config/kitty`)
