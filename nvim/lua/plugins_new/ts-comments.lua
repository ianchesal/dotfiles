-- Better commentstring handling per treesitter node (folke/ts-comments.nvim).
return {
  src = "https://github.com/folke/ts-comments.nvim",
  policy = { mode = "commit" },
  config = function()
    require("ts-comments").setup({})
  end,
}
