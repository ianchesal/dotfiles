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
        transparent = false, -- enable transparent background
        italic_comments = false, -- italicize comments
        hide_fillchars = true, -- replace all fillchars with ' ' for the ultimate clean look
        borderless_telescope = false, -- remove borders from telescope windows
        theme = {
          colors = {
            -- Use a slightly darker green
            green = "#06c258",
          },

          highlights = {
            -- Set indent scope to blue (instead of pink)
            MiniIndentScopeSymbol = { fg = "#5ea1ff" },
          },
        },
      })
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "tokyonight-night",
      colorscheme = "cyberdream",
    },
  },
}
