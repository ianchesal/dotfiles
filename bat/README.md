# dotfiles/bat

Configuration for [bat](https://github.com/sharkdp/bat), a `cat` clone with
syntax highlighting and Git integration. There is no rake task for this; point
bat at the config by setting `BAT_CONFIG_PATH` or placing `bat.conf` in bat's
config directory (`bat --config-dir`).

## Layout

```
bat.conf   Theme, pager, and syntax-mapping settings
```

The config sets the `Monokai Extended` theme, uses `less -FR` as the pager
(mouse scrolling support), and maps `.ignore` files to `.gitignore` highlighting.
