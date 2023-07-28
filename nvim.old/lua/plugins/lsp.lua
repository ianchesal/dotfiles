-- NOTE: This is where your plugins related to LSP can be installed.
--  The configuration is done in init.lua. Search for lspconfig to find it.
return {
	-- LSP Configuration & Plugins
	'neovim/nvim-lspconfig',
	dependencies = {
		-- Automatically install LSPs to stdpath for neovim
		{
			'williamboman/mason.nvim',
			config = true
		},
		'williamboman/mason-lspconfig.nvim',
		{
			"jose-elias-alvarez/null-ls.nvim",
		},


		-- Useful status updates for LSP
		-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
		{ 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },

		-- Additional lua configuration, makes nvim stuff amazing!
		'folke/neodev.nvim',
	},
}
