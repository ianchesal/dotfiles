return {
  src = "https://github.com/nvim-mini/mini.align",
  policy = { mode = "commit" },
  config = function()
    require("mini.align").setup({
      mappings = {
        start = "ga",
        start_with_preview = "gA",
      },
    })
  end,
}
