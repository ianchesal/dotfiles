---@type MappingsTable
local M = {}

-- initialize global var to false -> nvim-cmp turned off per default
vim.g.cmptoggle = true

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
    ["<leader>tcf"] = {
      "<cmd> lua require('cmp').setup.buffer { enabled = false } <CR>",
      "Turn nvim-cmp off in buffer",
    },
    ["<leader>tco"] = {
      "<cmd> lua require('cmp').setup.buffer { enabled = true } <CR>",
      "Turn nvim-cmp on in buffer",
    },
  },
}

-- more keybinds!

return M
