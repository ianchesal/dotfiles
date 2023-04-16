local M = {}

M.telescope = {
	-- Use <leader>fa instead ;)
	-- pickers = {
	-- 	find_files = {
	-- 		hidden = true,
	-- 		no_ignore = true,
	-- 		follow = true,
	-- 	},
	-- },
}

M.treesitter = {
	ensure_installed = {
		"bash",
		"c",
		"css",
		"git_rebase",
		"gitcommit",
		"gitignore",
		"html",
		"javascript",
		"javascript",
		"jq",
		"json",
		"jsonnet",
		"lua",
		"lua",
		"markdown",
		"markdown",
		"markdown_inline",
		"python",
		"ruby",
		"terraform",
		"tsx",
		"typescript",
		"typescript",
		"vim",
		"vim",
		"yaml",
	},
	ignore_install = {
		"norg",
	},
	indent = {
		enable = true,
		-- disable = {
		--   "python"
		-- },
	},
	endwise = {
		enable = false,
	},
}

M.mason = {
	ensure_installed = {
		-- lua stuff
		"lua-language-server",
		"stylua",

		-- web dev stuff
		"css-lsp",
		"html-lsp",
		"typescript-language-server",
		"deno",
		"prettier",
	},
}

-- git support in nvimtree
M.nvimtree = {
	git = {
		enable = true,
	},

	renderer = {
		highlight_git = true,
		icons = {
			show = {
				git = true,
			},
		},
	},
}

return M
