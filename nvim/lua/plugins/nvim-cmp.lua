return {
  "hrsh7th/nvim-cmp",
  config = {
    enabled = function()
      local context = require("cmp.config.context")
      local disabled = false
      disabled = disabled or (vim.api.nvim_get_option_value("buftype", { buf = 0 }) == "prompt")
      disabled = disabled or (vim.fn.reg_recording() ~= "")
      disabled = disabled or (vim.fn.reg_executing() ~= "")
      disabled = disabled or context.in_treesitter_capture("comment")
      return not disabled
    end,
  },
}
