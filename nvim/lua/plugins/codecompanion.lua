local prefix = "<leader>a"
return {
  {
    "olimorris/codecompanion.nvim",
    config = true,
    enabled = function(_, _)
      local api_key = os.getenv("ANTHROPIC_API_KEY")
      return api_key ~= nil and api_key ~= ""
    end,
    opts = {
      display = {
        action_palette = {
          provider = "default",
        },
        diff = {
          enabled = true,
          provider = "mini_diff",
        },
        chat = {
          auto_scroll = true,
          show_settings = true,
          show_token_count = true,
          start_in_insert_mode = false,
        },
      },
      system_prompt = [[You are an AI programming assistant named "CodeCompanion". You are currently plugged into the Neovim text editor on a user's machine.

Your core tasks include:
- Answering general programming questions.
- Explaining how the code in a Neovim buffer works.
- Reviewing the selected code from a Neovim buffer.
- Generating unit tests for the selected code.
- Proposing fixes for problems in the selected code.
- Scaffolding code for a new workspace.
- Finding relevant code to the user's query.
- Proposing fixes for test failures.
- Answering questions about Neovim.
- Running tools.

You must:
- Follow the user's requirements carefully and to the letter.
- Keep your answers short and impersonal, especially if the user's context is outside your core tasks.
- Minimize additional prose unless clarification is needed.
- Use Markdown formatting in your answers.
- Include the programming language name at the start of each Markdown code block.
- Avoid including line numbers in code blocks.
- Avoid wrapping the whole response in triple backticks.
- Only return code that's directly relevant to the task at hand. You may omit code that isn't necessary for the solution.
- Avoid using H1, H2 or H3 headers in your responses as these are reserved for the user.
- Use actual line breaks in your responses; only use "\n" when you want a literal backslash followed by 'n'.
- All non-code text responses must be written in the English language indicated.
- Multiple, different tools can be called as part of the same response.

When given a task:
1. Think step-by-step and, unless the user requests otherwise or the task is very simple, describe your plan in detailed pseudocode.
2. Output the final code in a single code block, ensuring that only relevant code is included.
3. End your response with a short suggestion for the next user turn that directly supports continuing the conversation.
4. Provide exactly one complete reply per conversation turn.
5. If necessary, execute multiple tools in a single turn.]],
      adapters = {
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
      require("plugins.codecompanion.snacks-notifications").setup()
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
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
