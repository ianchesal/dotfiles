local present, null_ls = pcall(require, "null-ls")

if not present then
	return
end

-- local b = null_ls.builtins

local formatting = null_ls.builtins.formatting
local lint = null_ls.builtins.diagnostics

local sources = {
	-- See: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#formatting

	-- webdev stuff
	formatting.deno_fmt, -- choosed deno for ts/js files cuz its very fast!
	formatting.prettier.with({ filetypes = { "html", "markdown", "css" } }), -- so prettier works only on these filetypes

	-- Lua
	formatting.stylua,

	-- cpp
	formatting.clang_format,

	-- Terraform
	formatting.terraform_fmt,
	lint.terraform_validate,

	-- Ruby w/Rubocop
	formatting.rubocop,
	lint.rubocop,

	-- YAML
	formatting.yq,

	-- Bash, zsh
	formatting.shfmt,
	lint.shellcheck,
}

-- Format on save from here: https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Formatting-on-save#sync-formatting
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
null_ls.setup({
	debug = true,
	sources = sources,
	-- you can reuse a shared lspconfig on_attach callback here
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					-- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
					-- vim.lsp.buf.formatting_sync()
          vim.lsp.buf.format({ bufnr = bufnr })
				end,
			})
		end
	end,
})
