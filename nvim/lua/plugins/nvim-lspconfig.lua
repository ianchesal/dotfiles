return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {
          filetypes = { "sh", "zsh" },
        },
        denols = {},
        diagnosticls = {},
        dockerls = {},
        helm_ls = {},
        json_ls = {},
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
        shellcheck = {},
        shlint = {},
        terraformls = {},
        tflint = {},
        tsserver = {},
        yamlls = {},
      },
    },
  },
}
