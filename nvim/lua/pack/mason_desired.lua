-- Shared registry of Mason packages the config intends to keep installed.
-- mason.lua and lspconfig.lua call register() from their config(); the
-- `rake nvim:mason_prune` script reads desired() to find orphaned packages
-- (installed on disk but no longer wanted) and uninstalls them.
--
-- Packages are keyed by source ("mason", "lspconfig") so the prune script can
-- refuse to run on a partial registry: loader.lua pcall-wraps each config(),
-- so a config() that errors at startup leaves its source unregistered — and
-- pruning then would wrongly delete every package that source owns.
local M = { _sources = {} }

-- source: a stable string id. names: a list of Mason *package* names (not
-- lspconfig server names — callers must map those to packages first).
function M.register(source, names)
  local set = M._sources[source] or {}
  for _, name in ipairs(names) do
    set[name] = true
  end
  M._sources[source] = set
end

-- The source ids that have registered at least once this session.
function M.sources()
  return vim.tbl_keys(M._sources)
end

-- Union of every source's package set, as a name -> true lookup.
function M.desired()
  local out = {}
  for _, set in pairs(M._sources) do
    for name in pairs(set) do
      out[name] = true
    end
  end
  return out
end

return M
