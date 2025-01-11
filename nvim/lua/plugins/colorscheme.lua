return {
  {
    "navarasu/onedark.nvim",
    lazy = true,
    priority = 1000,
    opts = {
      style = "deep",
      lualine = {
        transparent = true,
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "catppuccin",
      -- colorscheme = "tokyonight-night",
      colorscheme = "onedark",
      -- colorscheme = "quiet",
    },
  },
}
