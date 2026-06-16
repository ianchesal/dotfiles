# dotfiles/gemini

Configuration for the [Gemini CLI](https://github.com/google-gemini/gemini-cli),
Google's CLI coding agent. The CLI is installed from npm (`@google/gemini-cli`).

## Layout

```
GEMINI.md       Symlink to ../claude/CLAUDE.md (reuses the global memory/instructions)
gemini.rake     install / update / clean tasks
```

## Tasks

- `rake gemini` — install: create `~/.gemini` and npm-install `@google/gemini-cli`
- `rake gemini:update` — npm-update `@google/gemini-cli` (only if the `gemini` CLI is present)
- `rake gemini:clean` — remove `~/.gemini` and npm-uninstall the package

## Notes

- `rake gemini` is not wired into the top-level `rake all` (its `task all` hook is commented out); install it explicitly.
- `GEMINI.md` is a symlink to the shared Claude memory file, so both agents read the same global instructions.
