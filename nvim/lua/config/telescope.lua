local M = {}

function M.setup()
  require('telescope').setup({
    pickers = {
      find_files = {
        theme = 'dropdown'
      }
    },
    extensions = {
      project = {
        base_dirs = {
          -- {'~/src', max_depth = 4},
          {'~/.config', max_depth = 2},
        },
        hidden_files = true
      },
    },
  })
end

return M
