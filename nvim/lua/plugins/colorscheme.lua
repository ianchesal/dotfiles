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
      style = "night",
    },
  },

  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("cyberdream").setup({
        transparent = true, -- enable transparent background
        italic_comments = true, -- italicize comments
        hide_fillchars = true, -- replace all fillchars with ' ' for the ultimate clean look
      })
      -- vim.cmd("colorscheme cyberdream") -- set the colorscheme
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
      -- colorscheme = "cyberdream",
    },
  },
}
