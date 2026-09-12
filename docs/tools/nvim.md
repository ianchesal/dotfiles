# dotfiles/nvim

Self-managed Neovim configuration built on Neovim 0.12's native `vim.pack` —
no plugin-manager framework. Migrated off LazyVim in June 2026.

## Requirements

- Neovim 0.12+
- `git` and `jq` (required by the plugin update machinery)

## Layout

```
init.lua                 Entry point: config modules, then the pack loader
lua/config/              options.lua, keymaps.lua, autocmds.lua
lua/plugins/*.lua        One plugin spec per file
lua/pack/                Update machinery: delay.lua (pure core),
                         gitops.lua (git layer), loader.lua
scripts/update.lua       The delayed updater (run headless with -u NONE)
tests/*_spec.lua         Machinery tests (delay, gitops, loader)
pins.json                Authoritative pin state — GENERATED, never hand-edit
nvim-pack-lock.json      vim.pack's derived lockfile; must agree with pins.json
```

## Plugin specs

Each file in `lua/plugins/` returns a table:

```lua
return {
  src = "https://github.com/owner/repo",   -- full URL; vim.pack passes it to git clone verbatim
  policy = { mode = "commit" },            -- "commit" (default) | "tag" | "exempt"; optional days = N
  priority = 50,                           -- lower runs config() earlier (colorscheme 10 … default 50)
  config = function()                      -- plain setup() calls + vim.keymap.set
    require("repo").setup({ ... })
  end,
}
```

Policies: `commit` tracks the default branch with a 30-day delay; `tag`
tracks stable semver releases with the same delay; `exempt` takes updates
immediately (also the urgent-update escape hatch — set it, run
`rake nvim:update`, revert).

## Delayed updates

Updates are held back by first-observed timestamps recorded in `pins.json`:
a new upstream revision only becomes eligible 30 days (configurable per
plugin via `days`) after the updater first sees it. A spec with no pin entry
is a hard startup error — `rake nvim:update` is the only path that creates
pins.

The updater must run with `-u NONE` (the rake task does this); loading
init.lua first would pre-register the vim.pack specs and freeze update
targets.

## Tasks

- `rake nvim` — install (symlink) this config
- `rake nvim:update` — apply eligible plugin updates / bootstrap pins for new specs
- `rake nvim:outdated` — preview eligible updates without applying
- `rake nvim:commit` — verify pins.json/nvim-pack-lock.json consistency and commit them together

Adding a plugin: create the spec file, then `rake nvim:update` to bootstrap
its delayed pin. Removing one: delete the spec file, remove the pin and
lockfile entries, and delete the on-disk clone. See the
`managing-nvim-plugins` skill for the full procedure.

## Tests

```sh
nvim --headless -u NONE -l nvim/tests/delay_spec.lua
nvim --headless -u NONE -l nvim/tests/gitops_spec.lua
nvim --headless -u NONE -l nvim/tests/loader_spec.lua
```

## Code style

Lua is formatted with stylua (2-space indent, 120 column width) per
`stylua.toml`.
