-- From: https://github.com/alpha2phi/neovim-for-beginner/blob/10-autopairs/lua/config/autopairs.lua
local M = {}

function M.setup()
  local npairs = require "nvim-autopairs"
  npairs.setup {
    check_ts = true,
  }
  npairs.add_rules(require "nvim-autopairs.rules.endwise-lua")
end

return M
