---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require("custom.highlights")

M.ui = {
	theme = "rxyhn",
	theme_toggle = { "rxyhn", "rxyhn" },

	hl_override = highlights.override,
	hl_add = highlights.add,
	statusline = {
		separator_style = "block",
	},
	nvdash = {
		load_on_startup = false,
	},
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require("custom.mappings")

return M
