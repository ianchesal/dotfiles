local M = {}

function M.setup()
  require("nvim-tree").setup {
    disable_netrw = true,
    hijack_netrw = true,
    view = {
      width = 40,
    },
    renderer = {
      group_empty = true,
    },
    filters = {
      dotfiles = true,
      custom = { ".git" },
    },
  }
end

return M
