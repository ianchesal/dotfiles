return {
  -- {
  --   --  This theme doesn't support everything I use in LazyVim
  --   -- Use it but stuff doesn't quite pop as well
  --   "navarasu/onedark.nvim",
  --   opts = {
  --     style = "darker", -- Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
  --     lualine = {
  --       transparent = true,
  --     },
  --   },
  -- },

  -- {
  --   "catppuccin/nvim",
  --   name = "catppuccin",
  -- },

  {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    opts = {
      style = "night"
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },
}
