return {
  {
    "mason-org/mason.nvim",
    -- u/folke has pinned to 1.x in the main branch now
    -- version = "^1.0.0",
    opts = {
      ensure_installed = {
        "bash-language-server",
        "deno",
        "diagnostic-languageserver",
        "dockerfile-language-server",
        "hadolint",
        "helm-ls",
        "json-lsp",
        "jsonnet-language-server",
        "lua-language-server",
        "prettierd",
        "ruby-lsp",
        "rubocop",
        "shellcheck",
        "shfmt",
        "sqlls",
        "stylua",
        "terraform-ls",
        "tflint",
        "typescript-language-server",
        "yaml-language-server",
      },
    },
  },
  -- {
  --   "mason-org/mason-lspconfig.nvim",
  --   version = "^1.0.0",
  -- },
}
