return {
  "hrsh7th/nvim-cmp",
  config = {
    enabled = function()
      local context = require("cmp.config.context")
      local disabled = false
      disabled = disabled or (vim.api.nvim_buf_get_option(0, "buftype") == "prompt")
      disabled = disabled or (vim.fn.reg_recording() ~= "")
      disabled = disabled or (vim.fn.reg_executing() ~= "")
      disabled = disabled or context.in_treesitter_capture("comment")
      return not disabled
    end,
  },
}
