local overrides = require("custom.configs.overrides")

---@type NvPluginSpec[]
local plugins = {

  -- Override plugin definition options

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- format & linting
      {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          require "custom.configs.null-ls"
        end,
      },
    },
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },

  -- override plugin configs
  {
    "williamboman/mason.nvim",
    opts = overrides.mason
  },

  {
    'RRethy/nvim-treesitter-endwise',
    lazy = false,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    -- opts = overrides.treesitter,
    opts = {
      ensure_installed = {
        'bash',
        'javascript',
        'json',
        'lua',
        'markdown',
        'python',
        'ruby',
        'terraform',
        'typescript',
        'vim',
      },
      endwise = {
        enable = true,
      },
    },
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  },

  -- Install a plugin
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },

  {
    'echasnovski/mini.surround',
    lazy = false,
    config = function()
      require('mini.surround').setup()
    end
  },

  {
    'famiu/bufdelete.nvim',
    lazy = false,
  },

  {
    'tpope/vim-fugitive',
    lazy = false,
  },

  {
    'farmergreg/vim-lastplace',
    lazy = false,
  }



  -- To make a plugin not be loaded
  -- {
  --   "NvChad/nvim-colorizer.lua",
  --   enabled = false
  -- },

}

return plugins
