return {
  src = "https://github.com/wurli/contextindent.nvim",
  policy = { mode = "commit" },
  config = function()
    -- (old lazy.nvim spec declared a treesitter dependency; ordering now
    -- comes from loader priorities — treesitter runs at priority 20, this
    -- at default 50)
    require("contextindent").setup({
      -- pattern = "*" applies to all files; narrow if needed
      -- (see :help autocommand-pattern)
      pattern = "*",
    })
  end,
}
