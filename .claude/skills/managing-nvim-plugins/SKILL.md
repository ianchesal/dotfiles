---
name: managing-nvim-plugins
description: Use when adding, removing, or reconfiguring a Neovim plugin in this repo (nvim/lua/plugins/), changing a plugin's update policy or pinned revision, or cleaning up plugin state in pins.json / nvim-pack-lock.json
---

# Managing nvim Plugins (vim.pack + delayed pins)

## Overview

Plugins are vim.pack-managed. `nvim/pins.json` is the authoritative pin state; `nvim/nvim-pack-lock.json` is vim.pack's own lockfile. **`rake nvim:update` is the only thing that creates pins; vim.pack is the only thing that edits its lockfile.** Hand-editing either with sed/python is how state drifts across machines.

## Adding a plugin

1. **Collision check first** — for every keymap the plugin will bind: `grep -rn '<leader>xy' nvim/lua/`. Hits in `config/keymaps.lua` or another spec must be resolved deliberately (move/rename the old one), never silently clobbered.
2. Create `nvim/lua/plugins/<name>.lua` where `<name>` = the repo basename of `src`:

```lua
return {
  src = "https://github.com/owner/repo", -- FULL https URL; vim.pack clones it verbatim
  policy = { mode = "commit" }, -- or "tag" (stable semver releases) / "exempt" (no delay)
  -- priority = N,  -- only if config() must run before the default-50 plugins
  --                -- (ladder: colorscheme 10, icons 14, snacks 15, treesitter 20,
  --                --  which-key 25, mason→lspconfig 30-32, blink 40)
  config = function()
    require("repo").setup({})
    vim.keymap.set("n", "<leader>xy", "<cmd>Thing<cr>", { desc = "Thing" })
  end,
}
```

   Plugin-bound keymaps live **here**, not in `config/keymaps.lua`. New `<leader>` prefix → add the group to `nvim/lua/plugins/which-key.lua`.
3. `stylua nvim/lua/plugins/<name>.lua`
4. `rake nvim:update` — bootstraps a delayed pin (newest rev ≥30 days old by commit date; the one date-trusting moment, accepted by design). Until this runs, **startup hard-errors on the unpinned plugin** — that's intentional, not a bug to work around.
5. Verify: `nvim --headless "+lua print('ok')" +qa` is clean, and the keymap registered:
   `nvim --headless "+lua assert(vim.fn.maparg('<leader>xy','n') ~= '')" +qa`
6. Commit the spec + `pins.json` + `nvim-pack-lock.json` together (they must stay consistent).

## Removing a plugin

1. `git rm nvim/lua/plugins/<name>.lua`
2. `grep -rn '<name>' nvim/lua/` — fix references from other specs/config (lualine components, which-key groups, keymaps that call into it).
3. Remove the on-disk clone AND the lockfile entry **via vim.pack** (this is the step everyone gets wrong — never sed the lockfile):

```bash
nvim --headless -u NONE "+lua vim.pack.del({ '<name>' })" +qa
```

4. Drop the stale pin, preserving the canonical jq formatting (this is bookkeeping the updater doesn't do — stale pins otherwise persist forever):

```bash
jq --sort-keys 'del(.plugins["<name>"])' nvim/pins.json > /tmp/pins.json && mv /tmp/pins.json nvim/pins.json
```

5. Verify: clean headless startup; `grep -rn '<name>' nvim/` hits nothing.
6. Commit the deletion + `pins.json` + `nvim-pack-lock.json` together.

## Editing a plugin

- **opts/keymaps**: edit the spec's `config()`, stylua, verify clean startup. No pin impact.
- **Urgent update before the 30-day window**: set `policy = { mode = "exempt" }`, run `rake nvim:update`, revert the policy. The never-downgrade rule keeps the plugin ahead until the window catches up — expected, not a bug.
- **Changing `src`** (fork/rename): vim.pack deletes and reinstalls from the new URL on next launch; treat the pin as stale (remove it per step 4 above, then `rake nvim:update` to re-bootstrap).

## Red flags — stop and use the right tool

| If you're about to… | Do this instead |
|---|---|
| sed/python/jq-edit `nvim-pack-lock.json` | `vim.pack.del()` / `rake nvim:update` own that file |
| hand-write a pin rev into `pins.json` | `rake nvim:update` is the only pin creator |
| use `owner/repo` shorthand in `src` | full `https://` URL — vim.pack clones it verbatim |
| add a keymap without grepping for its lhs | collision check across `nvim/lua/` first |
| commit `pins.json` without the lockfile (or vice versa) | they travel together; `rake nvim:commit` enforces consistency |
| "fix" the unpinned-plugin startup error with a branch fallback | run `rake nvim:update`; the hard error is the security model |
