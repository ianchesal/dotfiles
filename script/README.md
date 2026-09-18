# dotfiles/script

Helper scripts that support the dotfiles, run directly or wired up by `just`
tasks defined elsewhere in the repo.

## Layout

```
gen-claude-completions  Generates ~/.config/zsh/completions/_claude from `claude --help`
```

`gen-claude-completions.py` parses `claude --help` and writes a zsh completion
spec to `${ZDOTDIR:-~/.config/zsh}/completions/_claude`. Run it directly or via
`just claude::gen-completions`; the generated file carries a "do not edit by
hand" header.

It writes to the **live** completions dir, not the chezmoi source state. The
spec is derived from the locally installed `claude --version`, so it is
machine-local: tracking it dirtied the repo on every version bump and let
`chezmoi apply` overwrite one machine's spec with another's.

`just claude::update` regenerates it whenever the version moves, and also calls
`--if-missing` to seed a machine that has no spec yet. Pass `--if-missing` to
exit quietly when one already exists; the script owns the destination path, so
nothing else needs to know it.
