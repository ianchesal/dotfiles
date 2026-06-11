return {
  src = "https://github.com/folke/tokyonight.nvim",
  policy = { mode = "commit" },
  priority = 10, -- colorscheme loads before UI plugins read highlight groups
  config = function()
    require("tokyonight").setup({
      style = "night",
      on_colors = function(colors)
        colors.bg = "#000000" -- I like a very dark background
      end,
    })
    vim.cmd.colorscheme("tokyonight")
  end,
}
