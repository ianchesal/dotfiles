return {
  "saghen/blink.cmp",
  opts = {
    enabled = function()
      local disabled = false
      -- local success, node = pcall(vim.treesitter.get_node)
      disabled = disabled or (vim.tbl_contains({ "markdown" }, vim.bo.filetype))
      disabled = disabled or (vim.bo.buftype == "prompt")
      disabled = disabled or (vim.fn.reg_recording() ~= "")
      disabled = disabled or (vim.fn.reg_executing() ~= "")
      -- disabled = disabled
      --   or (success and node and vim.tbl_contains({ "comment", "line_comment", "block_comment" }, node:type()))
      return not disabled
    end,
    sources = {
      default = function()
        local success, node = pcall(vim.treesitter.get_node)
        if success and node and vim.tbl_contains({ "comment", "line_comment", "block_comment" }, node:type()) then
          return { "buffer" }
        else
          return { "lsp", "path", "snippets", "buffer", "copilot" }
        end
      end,
    },
  },
}
