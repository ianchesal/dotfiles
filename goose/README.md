# dotfiles/goose

Configuration for [goose](https://github.com/block/goose), Block's CLI coding
agent. The directory is symlinked to `~/.config/goose`. The CLI is installed via
the official installer (`download_cli.sh` with `CONFIGURE=false`).

## Layout

```
config.yaml         Provider/model (anthropic, claude-sonnet-4), smart_approve mode, bundled extensions
permission.yaml     Per-mode tool allow / ask-before / never-allow lists
.goosehints         Global agent hints (preferences, init behavior, workflow)
goose.rake          install / update / clean tasks
```

## Tasks

- `rake goose` — install: symlink `~/.config/goose` and run the goose installer
- `rake goose:update` — run `goose update` (only if the `goose` CLI is present)
- `rake goose:clean` — remove the `~/.config/goose` symlink and the `goose` binary

## Notes

- `config.yaml` runs in `smart_approve` mode against the Anthropic API and enables the bundled `computercontroller`, `developer`, and `memory` extensions.
- `permission.yaml` asks before `developer__shell` / `developer__text_editor` in smart-approve mode.
