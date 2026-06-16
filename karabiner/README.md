# dotfiles/karabiner

[Karabiner-Elements](https://karabiner-elements.pqrs.org/) configuration. Karabiner
is a macOS keyboard customizer. macOS-only; deployed to `~/.config/karabiner` via XDG.

## Layout

```
karabiner.json                                  Main config: global options, the Default profile,
                                                device rules, fn-key mappings, complex modifications
assets/complex_modifications/1682691750.json    Importable "Amethyst Mode" complex-modification ruleset
karabiner.rake                                  Install/clean rake tasks
```

## Config notes

- Caps Lock is remapped to Backspace on the internal and a paired external keyboard.
- The fn row maps to standard macOS media/brightness/Mission Control/Spotlight/dictation
  consumer keys.
- The active complex modifications implement an "Amethyst Mode": holding `9` enters a
  modal layer (and `9`+`0` a second layer) whose keys translate to the Amethyst tiling
  window manager's option+shift shortcuts — layout cycling, pane resize, focus/swap
  windows, and screen targeting. Tapped alone, `9`/`0`/`8` still type their digits.
- `assets/complex_modifications/1682691750.json` is the full Amethyst Mode ruleset in
  Karabiner's importable format; the live `karabiner.json` carries a trimmed subset of it.

## Tasks

- `rake karabiner` — install (symlink) this config
- `rake karabiner:update` — no-op (there are no submodules in this repo)
