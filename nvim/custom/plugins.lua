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

	-- override plugin configs
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

	-- Install a plugin
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

	-- To make a plugin not be loaded
	-- {
	--   "NvChad/nvim-colorizer.lua",
	--   enabled = false
	-- },
}

return plugins
