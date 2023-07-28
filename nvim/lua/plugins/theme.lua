return {
  {
    "EdenEast/nightfox.nvim", -- https://github.com/EdenEast/nightfox.nvim
    lazy = true,
    priority = 1000,
    config = function()
      require("nightfox").setup({
        options = {
          transparent = false,
        },
      })
      -- Pick one of: nightfox, dayfox, dawnfox, duskfox, nordfox, terafox, carbonfox
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
