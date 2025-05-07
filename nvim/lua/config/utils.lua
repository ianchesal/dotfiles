-- General utility functions
local M = {}

-- Find the project root directory
function M.get_project_root()
  -- Look for common project files/directories
  local markers = { "Gemfile", ".git", "." }
  local paths = vim.fs.find(markers, {
    upward = true,
    stop = vim.loop.os_homedir(),
    path = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  })
  
  return paths[1] and vim.fs.dirname(paths[1]) or vim.loop.cwd()
end

return M