# dotfiles/copilot

Configuration for the [GitHub Copilot CLI](https://github.com/github/copilot)
agent. The directory is symlinked to `~/.config/.copilot`. The CLI is installed
from npm (`@github/copilot`).

## Layout

```
config.json     Symlink to the live Copilot config (managed by the CLI)
copilot.rake    install / update / clean tasks
```

## Tasks

- `rake copilot` — install: symlink `~/.config/.copilot` and npm-install `@github/copilot`
- `rake copilot:update` — npm-install `@github/copilot` again to pull the latest (only if the `copilot` CLI is present)
- `rake copilot:clean` — remove the `~/.config/.copilot` symlink and npm-uninstall the package
