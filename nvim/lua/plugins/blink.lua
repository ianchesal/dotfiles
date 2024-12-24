return {
  "saghen/blink.cmp",
  opts = {
    enabled = function()
      local disabled = false
      -- local node = vim.treesitter.get_node()
      disabled = disabled or (vim.tbl_contains({ "markdown" }, vim.bo.filetype))
      disabled = disabled or (vim.bo.buftype == "prompt")
      disabled = disabled or (vim.fn.reg_recording() ~= "")
      disabled = disabled or (vim.fn.reg_executing() ~= "")
      -- disabled = disabled or (node ~= nil and string.find(node:type(), "comment") ~= nil)
      return not disabled
    end,
  },
}
