# dotfiles/codex

Configuration for [Codex](https://github.com/openai/codex), OpenAI's CLI coding
agent. The directory is symlinked to `~/.config/codex`. The CLI is installed
from npm (`@openai/codex`).

## Layout

```
config.yaml         Default model (o4-mini), full-auto error mode, notifications
instructions.md     Global agent instructions
codex.rake          install / update / clean tasks
```

## Tasks

- `rake codex` — install: symlink `~/.config/codex` and npm-install `@openai/codex`
- `rake codex:update` — npm-update `@openai/codex` (only if the `codex` CLI is present)
- `rake codex:clean` — remove the `~/.config/codex` symlink and npm-uninstall the package

## Notes

- `rake codex` is not wired into the top-level `rake all` (its `task all` hook is commented out); install it explicitly.
- `config.yaml` sets `fullAutoErrorMode: ask-user` and `notify: true`.
