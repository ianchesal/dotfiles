-- mason-lspconfig v2 bridges mason packages to vim.lsp.enable():
-- with `automatic_enable` (default true) every mason-installed server is
-- enabled automatically.
--
-- setup() is intentionally NOT called here: lspconfig.lua (priority 32)
-- calls require("mason-lspconfig").setup() AFTER all vim.lsp.config()
-- definitions, so automatic_enable sees the final server configs and an
-- exclude list for disabled servers. Only servers mason does not manage are
-- vim.lsp.enable()-d directly there -- no double-enabling. This mirrors
-- LazyVim, which also declared mason-lspconfig with an empty config and ran
-- setup() from its lspconfig spec.
return {
  src = "https://github.com/mason-org/mason-lspconfig.nvim",
  policy = { mode = "commit" },
  priority = 31,
}
