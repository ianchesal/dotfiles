return {
  "olimorris/codecompanion.nvim",
  config = true,
  enabled = function(_, _)
    local api_key = os.getenv("ANTHROPIC_API_KEY")
    return api_key ~= nil and api_key ~= ""
  end,
  keys = {
    {
      "<leader>ac",
      "<cmd>CodeCompanionChat<cr>",
      desc = "CodeCompanion chat mode",
      mode = { "n", "v", "x" },
    },
    {
      "<leader>aa",
      "<cmd>CodeCompanionActions<cr>",
      desc = "CodeCompanion actions palette",
      mode = { "n", "v", "x" },
    },
  },
  opts = {
    display = {
      action_palette = {
        provider = "default",
      },
      chat = {
        auto_scroll = false,
        show_settings = true,
        show_token_count = true,
        start_in_insert_mode = false,
      },
    },
    adapters = {
      -- TODO: Switch to reading this from 1Password using the `op` CLI which CodeCompanion supports
      --       See: https://codecompanion.olimorris.dev/configuration/adapters.html#setting-an-api-key
      anthropic = function()
        return require("codecompanion.adapters").extend("anthropic", {
          schema = {
            model = {
              default = "claude-3-5-sonnet-latest",
            },
            max_tokens = {
              default = 8192,
            },
            temperature = {
              default = 0.2,
            },
          },
          env = {
            api_key = "ANTHROPIC_API_KEY",
          },
        })
      end,
    },
    strategies = {
      chat = {
        adapter = "anthropic",
      },
      command = {
        adapter = "anthropic",
      },
      inline = {
        adapter = "anthropic",
      },
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
}
