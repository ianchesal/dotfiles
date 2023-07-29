return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- Automatically format on save
      autoformat = true,
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
        rubocop = {},
        sqlls = {},
        solargraph = {},
        terraformls = {},
        tsserver = {},
        yamlls = {},
      },
    },
  },
}
