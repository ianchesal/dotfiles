# dotfiles/opencode

Configuration for [opencode](https://opencode.ai), a CLI coding agent. The
directory is symlinked to `~/.config/opencode`. The CLI is installed from npm
(`opencode-ai`).

## Layout

```
opencode.json   Schema-validated config: model (anthropic/claude-sonnet-4), theme, autoshare/autoupdate
AGENTS.md       Agent instructions — the Think → Plan → Iterate → Execute workflow
opencode.rake   install / update / clean tasks
```

## Tasks

- `rake opencode` — install: symlink `~/.config/opencode` and npm-install `opencode-ai`
- `rake opencode:update` — run `opencode upgrade` (only if the `opencode` CLI is present)
- `rake opencode:clean` — remove the `~/.config/opencode` symlink, `~/.local/share/opencode`, and npm-uninstall the package

## Notes

- `opencode.json` validates against `https://opencode.ai/config.json` and sets `autoupdate: true`, `autoshare: false`, theme `github`.
- `AGENTS.md` defines the structured 4-phase collaborative workflow (deep analysis, strategic planning, iteration, execution) plus security and file-operation guidelines.
