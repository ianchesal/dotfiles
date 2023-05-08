local overrides = require("custom.configs.overrides")

---@type NvPluginSpec[]
local plugins = {

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- format & linting
      {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          require("custom.configs.null-ls")
        end,
      },
    },
    config = function()
      require("plugins.configs.lspconfig")
      require("custom.configs.lspconfig")
    end, -- Override to setup mason-lspconfig
  },

  {
    "nvim-telescope/telescope.nvim",
    opts = overrides.telescope,
  },

  {
    "williamboman/mason.nvim",
    opts = overrides.mason,
  },

  {
    "RRethy/nvim-treesitter-endwise",
    lazy = true,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  },

  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },

  {
    "echasnovski/mini.surround",
    lazy = false,
    config = function()
      require("mini.surround").setup()
    end,
  },

  {
    "tpope/vim-fugitive",
    lazy = false,
  },

  {
    "farmergreg/vim-lastplace",
    lazy = false,
  },

  {
    "rafamadriz/friendly-snippets",
    lazy = false,
    config = function()
      require("luasnip").filetype_extend("ruby", { "rails" })
    end,
  },

  {
    -- For working with Ruby blocks
    -- See: https://github.com/chrisgrieser/nvim-various-textobjs#list-of-text-objects
    "chrisgrieser/nvim-various-textobjs",
    opts = { useDefaultKeymaps = true },
    lazy = false,
  },

  {
    "iamcco/markdown-preview.nvim",
    config = function()
      vim.fn["mkdp#util#install"]()
    end,
    lazy = false,
  },

  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    opts = overrides.copilot,
  },

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      {
        "zbirenbaum/copilot-cmp",
        config = function()
          require("copilot_cmp").setup()
        end,
      },
    },
    opts = {
      sources = {
        { name = "nvim_lsp", group_index = 2 },
        { name = "copilot",  group_index = 2 },
        { name = "luasnip",  group_index = 2 },
        { name = "buffer",   group_index = 2 },
        { name = "nvim_lua", group_index = 2 },
        { name = "path",     group_index = 2 },
      },
    },
  },
}

return plugins
