return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "default",
    },
    enabled = function()
      local node = vim.treesitter.get_node()
      local disabled = false
      disabled = disabled or (vim.tbl_contains({ "markdown" }, vim.bo.filetype))
      disabled = disabled or (vim.bo.buftype == "prompt")
      disabled = disabled or (vim.fn.reg_recording() ~= "")
      disabled = disabled or (vim.fn.reg_executing() ~= "")
      disabled = disabled or (node and string.find(node:type(), "comment"))
      return not disabled
    end,
  },
}
