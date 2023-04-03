---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require "custom.highlights"

M.ui = {
  theme = "tokyodark",
  theme_toggle = { "tokyonight", "tokyodark" },

  hl_override = highlights.override,
  hl_add = highlights.add,
  statusline = {
    separator_style = "block",
  },
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require "custom.mappings"

return M
