return {
  -- { "EdenEast/nightfox.nvim", lazy = false, priority = 1000 },
  -- { "bluz71/vim-moonfly-colors", lazy = false, priority = 1000 },
  -- { "bluz71/vim-nightfly-colors", lazy = false, priority = 1000 },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        -- transparent = true,
        -- terminal_colors = false,
        -- on_colors = function(colors)
        --   colors.bg = "#000000" -- I like a very dark background
        -- end,
      })
    end,
  },
  -- { "navarasu/onedark.nvim", lazy = false, priority = 1000, opts = { style = "deep", lualine = { transparent = true } }, },
  -- { "olimorris/onedarkpro.nvim", lazy = false, priority = 1000 },
  -- { "projekt0n/github-nvim-theme", lazy = false, priority = 1000 },
  -- { "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },
  -- { "scottmckendry/cyberdream.nvim", lazy = false, priority = 1000 },
  {
    "github-main-user/lytmode.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("lytmode").setup()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "catppuccin",
      -- colorscheme = "cyberdream",
      -- colorscheme = "github_dark_default",
      -- colorscheme = "moonfly",
      -- colorscheme = "onedark",
      -- colorscheme = "onedark_dark",
      -- colorscheme = "quiet",
      -- colorscheme = "tokyonight",
      colorscheme = "lytmode",
    },
  },
}
