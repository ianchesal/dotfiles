-- Dump resolved LazyVim state for transcription.
-- Run with the OLD (LazyVim) config active — see Task 1 Step 3 for the exact
-- invocation (loadfile through the active config; plain -l would skip init.lua).
local function dump(path, tbl)
  local f = assert(io.open(path, "w"))
  f:write(vim.inspect(tbl))
  f:close()
end

return function()
  local out = vim.fn.stdpath("config") .. "/.snapshot"
  vim.fn.mkdir(out, "p")

  local lazy_config = require("lazy.core.config")
  local Plugin = require("lazy.core.plugin")

  -- 0. Force-load EVERY plugin in-process (':Lazy load all' is not a
  -- documented form, and a partially-loaded dump silently misses keymaps).
  local plugin_names = vim.tbl_keys(lazy_config.plugins)
  local load_ok, load_err = pcall(function()
    require("lazy").load({ plugins = plugin_names })
  end)
  if not load_ok then
    vim.notify("Warning: force-load encountered error: " .. tostring(load_err), vim.log.levels.WARN)
  end

  -- 1. Per-plugin resolved opts and keys specs
  local opts_by_plugin, keys_by_plugin = {}, {}
  for name, plugin in pairs(lazy_config.plugins) do
    local ok, opts = pcall(Plugin.values, plugin, "opts", false)
    if ok then
      opts_by_plugin[name] = opts
    end
    local kok, keys = pcall(Plugin.values, plugin, "keys", true)
    if kok then
      keys_by_plugin[name] = keys
    end
  end
  dump(out .. "/opts.lua", opts_by_plugin)
  dump(out .. "/keys.lua", keys_by_plugin)

  -- 2. All active keymaps (plugins force-loaded above)
  local maps = {}
  for _, mode in ipairs({ "n", "v", "x", "s", "o", "i", "c", "t" }) do
    maps[mode] = vim.api.nvim_get_keymap(mode)
  end
  dump(out .. "/keymaps.lua", maps)

  -- 3. Options LazyVim sets (diff against defaults)
  local opts_info = vim.api.nvim_get_all_options_info()
  local changed = {}
  for name, info in pairs(opts_info) do
    if info.was_set then
      changed[name] = vim.api.nvim_get_option_value(name, {})
    end
  end
  dump(out .. "/options.lua", changed)

  -- 4. Autocmds
  dump(out .. "/autocmds.lua", vim.api.nvim_get_autocmds({}))

  -- 5. Treesitter parser list (ensure_installed resolved)
  local ts_ok, ts_config = pcall(require, "nvim-treesitter.configs")
  if ts_ok then
    dump(
      out .. "/parsers.lua",
      ts_config.get_ensure_installed_parsers and ts_config.get_ensure_installed_parsers()
        or (opts_by_plugin["nvim-treesitter"] and opts_by_plugin["nvim-treesitter"].ensure_installed)
    )
  elseif opts_by_plugin["nvim-treesitter"] and opts_by_plugin["nvim-treesitter"].ensure_installed then
    -- nvim-treesitter.configs not available headless; fall back to resolved opts
    dump(out .. "/parsers.lua", opts_by_plugin["nvim-treesitter"].ensure_installed)
  end
  print("snapshot written to " .. out)
end
