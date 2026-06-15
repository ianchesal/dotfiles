-- Removes Mason packages that are installed but no longer wanted by the
-- config — e.g. a tool dropped from mason.lua's ensure_installed, or an LSP
-- dropped from lspconfig.lua's servers. This is the Mason analogue of
-- `rake nvim:prune` (which prunes on-disk plugin clones against pins.json).
--
-- Unlike scripts/update.lua, this MUST run with the FULL config loaded (no
-- `-u NONE`): the "keep these" set is assembled at startup when mason.lua and
-- lspconfig.lua call pack.mason_desired.register() from their config().
-- `rake nvim:mason_prune` invokes it via `nvim --headless -c "luafile ..."`.
--
-- Set _G.MASON_PRUNE_DRY = true to list orphans without uninstalling.
local dry_run = _G.MASON_PRUNE_DRY == true

local desired_mod = require("pack.mason_desired")

-- Refuse to prune on a partial registry. loader.lua pcall-wraps each config(),
-- so if one errored at startup its source is missing here — pruning would then
-- delete that source's packages. Better to bail loudly than over-delete.
local expected = { "mason", "lspconfig" }
local registered = {}
for _, source in ipairs(desired_mod.sources()) do
  registered[source] = true
end
for _, source in ipairs(expected) do
  if not registered[source] then
    io.stderr:write(
      ("mason_prune: source '%s' never registered — a config() likely errored at startup. Refusing to prune.\n"):format(
        source
      )
    )
    os.exit(1)
  end
end

local desired = desired_mod.desired()
local installed = require("mason-registry").get_installed_package_names()

local orphans = {}
for _, name in ipairs(installed) do
  if not desired[name] then
    table.insert(orphans, name)
  end
end
table.sort(orphans)

if #orphans == 0 then
  print("No orphaned Mason packages")
  return
end

if dry_run then
  print("Would remove orphaned Mason packages: " .. table.concat(orphans, ", "))
  return
end

print("Removing orphaned Mason packages: " .. table.concat(orphans, ", "))
local registry = require("mason-registry")
for _, name in ipairs(orphans) do
  local ok, pkg = pcall(registry.get_package, name)
  if ok then
    pkg:uninstall()
  end
end
print("Done")
