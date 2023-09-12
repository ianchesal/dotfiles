return {
  {
    -- "AlexvZyl/nordic.nvim",
    "EdenEast/nightfox.nvim",
    "bluz71/vim-moonfly-colors",
    "bluz71/vim-nightfly-colors",
    -- "catppuccin/nvim",
    -- "ellisonleao/gruvbox.nvim",
    -- "jacoborus/tender.vim",
    -- "mcchrish/zenbones.nvim",
    "projekt0n/github-nvim-theme",
    -- "rebelot/kanagawa.nvim",
    -- "rktjmp/lush.nvim",
  },

  {
    "navarasu/onedark.nvim",
    opts = {
      style = "darker", -- Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
      lualine = {
        transparent = true,
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onedark",
    },
  },
}
