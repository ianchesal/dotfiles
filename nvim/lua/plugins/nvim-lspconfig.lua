local lspconfig = require("lspconfig")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- Useful for debugging formatter issues
      format_notify = true,
      servers = {
        bashls = {
          filetypes = { "sh", "zsh" },
        },
        denols = {},
        diagnosticls = {},
        dockerls = {},
        helm_ls = {},
        jsonls = {},
        jsonnet_ls = {},
        lua_ls = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
        marksman = {},
        -- regols is not maanged by Mason. i install it with `brew install kitagry/tap/regols`.
        -- See: https://github.com/kitagry/regols
        regols = {},
        ruby_ls = {
          cmd = { "bundle", "exec", "ruby-lsp" },
          init_options = {
            formatter = "auto",
          },
          settings = {},
        },
        -- rubocop = {
        --   -- See: https://docs.rubocop.org/rubocop/usage/lsp.html
        --   cmd = { "bundle", "exec", "rubocop", "--lsp" },
        --   root_dir = lspconfig.util.root_pattern("Gemfile", ".git", "."),
        -- },
        sqlls = {},
        -- solargraph = {
        --   -- See: https://medium.com/@cristianvg/neovim-lsp-your-rbenv-gemset-and-solargraph-8896cb3df453
        --   cmd = { os.getenv("HOME") .. "/.asdf/shims/solargraph", "stdio" },
        --   root_dir = lspconfig.util.root_pattern("Gemfile", ".git", "."),
        --   settings = {
        --     solargraph = {
        --       autoformat = true,
        --       completion = true,
        --       diagnostics = true,
        --       folding = true,
        --       references = true,
        --       rename = true,
        --       symbols = true,
        --     },
        --   },
        -- },
        terraformls = {},
        tsserver = {},
        yamlls = {},
      },
    },
  },
}
