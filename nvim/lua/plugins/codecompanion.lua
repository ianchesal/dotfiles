local prefix = "<leader>a"
return {
  {
    "olimorris/codecompanion.nvim",
    config = true,
    enabled = function(_, _)
      local api_key = os.getenv("ANTHROPIC_API_KEY")
      return api_key ~= nil and api_key ~= ""
    end,
    keys = {
      {
        prefix .. "a",
        "<cmd>CodeCompanionActions<cr>",
        desc = "CodeCompanion action palette",
        mode = { "n", "v" },
      },
      {
        prefix .. "c",
        "<cmd>CodeCompanionChat Toggle<cr>",
        desc = "CodeCompanion chat mode",
        mode = { "n", "v" },
      },
      {
        prefix .. ".",
        "<cmd>CodeCompanionChat Add<cr>",
        desc = "CodeCompanion add selection to current chat",
        mode = { "v" },
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
        anthropic_claude35 = function()
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
        anthropic_claude37 = function()
          return require("codecompanion.adapters").extend("anthropic", {
            schema = {
              model = {
                default = "claude-3-7-sonnet-latest",
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
          adapter = "anthropic_claude35",
        },
        command = {
          adapter = "anthropic_claude35",
        },
        inline = {
          adapter = "anthropic_claude35",
        },
      },
    },
    init = function()
      require("plugins.codecompanion.fidget-spinner"):init()
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "j-hui/fidget.nvim",
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { prefix, group = "CodeCompanion", icon = "󱚦 ", mode = { "n", "v" } },
      },
    },
  },
}
