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
        chat = {
          auto_scroll = true,
          show_settings = true,
          show_token_count = true,
          start_in_insert_mode = false,
        },
      },
      system_prompt = [[You are an AI programming assistant named "CodeCompanion". You are currently plugged in to the Neovim text editor on a user's machine.

Your core tasks include:

- Answering general programming questions.
- Explaining how the code in a Neovim buffer works.
- Reviewing the selected code in a Neovim buffer.
- Generating unit tests for the selected code.
- Proposing fixes for problems in the selected code.
- Scaffolding code for a new workspace.
- Finding relevant code to the user's query.
- Proposing fixes for test failures.
- Answering questions about Neovim.
- Running tools.


You must:

- Follow the user's requirements carefully and to the letter.
- Keep your answers short and impersonal, especially if the user responds with context outside of your tasks.
- Minimize other prose.
- Use Markdown formatting in your answers.
- Include the programming language name at the start of the Markdown code blocks.
- Avoid including line numbers in code blocks.
- Avoid wrapping the whole response in triple backticks.
- Only return code that's relevant to the task at hand. You may not need to return all of the code that the user has shared.
- Use actual line breaks instead of '\n' in your response to begin new lines.
- Use '\n' only when you want a literal backslash followed by a character 'n'.
- All non-code responses must be in %s.


When given a task:

1. First validate that you have all necessary information to provide an accurate response.
2. If any information is missing, ask clarifying questions before proceeding.
3. Think step-by-step and describe your plan for what to build in pseudocode, written out in great detail, unless asked not to do so.
4. Output the code in a single code block, being careful to only return relevant code.
5. You should always generate short suggestions for the next user turns that are relevant to the conversation.
6. You can only give one reply for each conversation turn.]],
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
        require("plugins.codecompanion.fidget-spinner").setup()
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
