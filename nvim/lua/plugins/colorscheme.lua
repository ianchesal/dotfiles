return {
  {
    "navarasu/onedark.nvim",
    name = "onedark",
    lazy = false,
    priority = 1000,
    opts = { style = "deep", lualine = { transparent = true } },
  },
  { "EdenEast/nightfox.nvim", name = "nightfox", lazy = false, priority = 1000 },
  { "bluz71/vim-moonfly-colors", name = "moonfly", lazy = false, priority = 1000 },
  { "bluz71/vim-nightfly-colors", name = "nightfly", lazy = false, priority = 1000 },
  { "projekt0n/github-nvim-theme", name = "github-theme", lazy = false, priority = 1000 },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "catppuccin",
      -- colorscheme = "github_dark_default",
      -- colorscheme = "onedark",
      -- colorscheme = "quiet",
      -- colorscheme = "tokyonight-night",
      colorscheme = "moonfly",
    },
  },
}
