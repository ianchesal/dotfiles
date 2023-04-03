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
      -- Minimal set of treesitter parsers to install
      ensure_installed = {
        'bash',
        'git_rebase',
        'gitcommit',
        'gitignore',
        'javascript',
        'jq',
        'json',
        'jsonnet',
        'lua',
        'markdown',
        'python',
        'ruby',
        'terraform',
        'typescript',
        'vim',
        'yaml',
      },
      -- Never install these parses
      ignore_install = {
        'norg',
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
