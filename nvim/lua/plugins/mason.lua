return {
  {
    -- https://github.com/LazyVim/LazyVim/pull/6053#issuecomment-2865604700
    -- Fixes the LazyVim/Mason 2.0 incompatibility
    -- Will dump this once u/folke has an official fix after he gets back
    -- from his well-deserved vacation.
    "LazyVim/LazyVim",
    url = "https://github.com/dpetka2001/LazyVim",
    branch = "fix/mason-v2",
  },
  {
    "mason-org/mason.nvim",
    -- No need to pin to <v2 with the above fix
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
