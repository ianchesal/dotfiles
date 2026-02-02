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
        on_colors = function(colors)
          colors.bg = "#000000" -- I like a very dark background
        end,
      })
    end,
  },
  {
    "oskarnurm/koda.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
  },
  { "mistweaverco/vhs-era-theme.nvim", lazy = false, priority = 1000 },
  -- {
  --   "Mofiqul/vscode.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("vscode").setup({
  --       color_overrides = {
  --         vscBack = "#1F1F1F",
  --       },
  --     })
  --   end,
  -- },
  -- { "navarasu/onedark.nvim", lazy = false, priority = 1000, opts = { style = "deep", lualine = { transparent = true } }, },
  { "olimorris/onedarkpro.nvim", lazy = false, priority = 1000 },
  -- { "projekt0n/github-nvim-theme", lazy = false, priority = 1000 },
  -- { "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },
  -- { "scottmckendry/cyberdream.nvim", lazy = false, priority = 1000 },
  -- {
  --   "github-main-user/lytmode.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("lytmode").setup({
  --       color_overrides = {
  --         -- I used: https://mdigi.tools/darken-color/#2d3039 to darken the default background color
  --         lytBack = "#22242b",
  --       },
  --     })
  --   end,
  -- },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "catppuccin",
      -- colorscheme = "cyberdream",
      -- colorscheme = "github_dark_default",
      -- colorscheme = "koda",
      -- colorscheme = "lytmode",
      -- colorscheme = "moonfly",
      -- colorscheme = "onedark",
      -- colorscheme = "onedark_dark",
      -- colorscheme = "quiet",
      colorscheme = "tokyonight",
      -- colorscheme = "vhs-era-theme",
      -- colorscheme = "vscode",
    },
  },
}
