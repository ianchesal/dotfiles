# dotfiles/serena

Configuration for [Serena](https://github.com/oraios/serena), a coding-agent
toolkit / MCP server providing semantic code tools. This directory is symlinked
to `~/.serena`; the Serena source itself is cloned into `serena/.serena`.

## Layout

```
serena_config.tmpl.yml   Template config seeded into serena_config.yml on first install
serena.rake              install / update / clean tasks
.serena/                 (generated) git clone of oraios/serena
serena_config.yml        (generated) active config; copied from the template, repo path appended to projects:
```

## Tasks

- `rake serena` — install: clone `oraios/serena` into `.serena/`, seed `serena_config.yml` from the template (appending the dotfiles repo to `projects:`), and symlink `~/.serena`
- `rake serena:update` — `git restore .` then `git pull` in the Serena clone
- `rake serena:clean` — remove the `.serena/` clone, the generated `serena_config.yml`, and the `~/.serena` symlink

## Notes

- `rake serena` is not wired into the top-level `rake all` (its `task all` hook is commented out); install it explicitly.
- `serena_config.yml` is generated and not committed; the trailing `projects:` list is managed by Serena — register projects by asking Serena to activate them.
