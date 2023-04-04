---@type MappingsTable
local M = {}

M.disabled = {
	n = {
		-- ['<leader>b'] = '',
	},
}

M.general = {
	n = {
		[";"] = { ":", "enter command mode", opts = { nowait = true } },
		-- ["<leader>bq"] = {"<cmd> Bdelete <CR>", "Delete buffer", opts = { noremap = true } }, -- Use <leader>x in NV Chad
		["<leader>gg"] = { "<cmd> Git <CR>", "git fugitive", opts = { noremap = true } },
	},
}

-- more keybinds!

return M
