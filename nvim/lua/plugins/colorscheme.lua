local cyberdream_dashboard = {
  -- These are Cyberdream colours. I like them better on the Dashboard
  -- even when I'm using another theme.
  DashboardHeader = { fg = "#bd5eff" },
  DashboardFooter = { fg = "#5ef1ff" },
  -- dashboard-nvim: doom theme
  DashboardShortCut = { fg = "#ffbd5e" },
  DashboardDesc = { fg = "#ffbd5e" },
  DashboardKey = { fg = "#5eff6c" },
  DashboardIcon = { fg = "#5ea1ff" },
  -- dashboard-nvim: hyper theme
  DashboardProjectTitle = { fg = "#5ea1ff" },
  DashboardProjectTitleIcon = { fg = "#ffbd5e" },
  DashboardProjectIcon = { fg = "#ffbd5e" },
  DashboardMruTitle = { fg = "#5ea1ff" },
  DashboardMruIcon = { fg = "#ffbd5e" },
  DashboardFiles = { fg = "#5ef1ff" },
  DashboardShortCutIcon = { fg = "#ff5ea0" },
}

return {
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
    "navarasu/onedark.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "deep",
      lualine = {
        transparent = true,
      },
      highlights = cyberdream_dashboard,
    },
  },

  -- {
  --   "sontungexpt/witch",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {},
  -- },

  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "tokyonight-night",
      colorscheme = "onedark",
      -- colorscheme = "cyberdream",
      -- colorscheme = "witch",
    },
  },
}
