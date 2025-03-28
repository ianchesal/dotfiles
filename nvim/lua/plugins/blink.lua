return {
  "saghen/blink.cmp",
  opts = {
    enabled = function()
      local disabled = false
      local success, node = pcall(vim.treesitter.get_node)
      -- disabled = disabled or (vim.tbl_contains({ "markdown" }, vim.bo.filetype))
      disabled = disabled or (vim.bo.buftype == "prompt")
      disabled = disabled or (vim.fn.reg_recording() ~= "")
      disabled = disabled or (vim.fn.reg_executing() ~= "")
      disabled = disabled
        or (success and node ~= nil and vim.tbl_contains({ "comment", "line_comment", "block_comment" }, node:type()))

      return not disabled
    end,
    -- Stolen from AstroVim
    completion = {
      list = { selection = { preselect = false, auto_insert = true } },
    },
    keymap = {
      ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-N>"] = { "select_next", "show" },
      ["<C-P>"] = { "select_prev", "show" },
      ["<C-J>"] = { "select_next", "fallback" },
      ["<C-K>"] = { "select_prev", "fallback" },
      ["<C-U>"] = { "scroll_documentation_up", "fallback" },
      ["<C-D>"] = { "scroll_documentation_down", "fallback" },
      ["<C-e>"] = { "hide", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
      ["<Tab>"] = {
        "snippet_forward",
        "select_next",
        function(cmp)
          if has_words_before() or vim.api.nvim_get_mode().mode == "c" then
            return cmp.show()
          end
        end,
        "fallback",
      },
      ["<S-Tab>"] = {
        "snippet_backward",
        "select_prev",
        function(cmp)
          if vim.api.nvim_get_mode().mode == "c" then
            return cmp.show()
          end
        end,
        "fallback",
      },
    },
  },
}
