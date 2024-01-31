return {
  {
    "folke/which-key.nvim",
    opts = {
      plugins = { spelling = false },
      defaults = {
        ["<leader>l"] = { name = "+lsp" },
        ["<leader>m"] = { name = "+markdown" },
        ["<leader>v"] = { name = "+terminal" },
      },
    },
  },
}
