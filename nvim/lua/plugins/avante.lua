local prefix = "<Leader>a"
return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = true,
    -- commit = "51eb8fc2d92c5e1ab26a92b379a810e2a04e21c9", -- set this if you want to pin to a commit
    version = false, -- set this if you want to always pull the latest change
    enabled = function(_, _)
      local api_key = os.getenv("ANTHROPIC_API_KEY")
      return api_key ~= nil and api_key ~= ""
    end,
    opts = {
      -- add any opts here
      mappings = {
        ask = prefix .. "<CR>",
        edit = prefix .. "e",
        refresh = prefix .. "r",
        focus = prefix .. "f",
        toggle = {
          default = prefix .. "t",
          debug = prefix .. "d",
          hint = prefix .. "h",
          suggestion = prefix .. "s",
          repomap = prefix .. "R",
        },
        diff = {
          next = "]c",
          prev = "[c",
        },
        files = {
          add_current = prefix .. ".",
        },
      },
      behaviour = {
        auto_suggestions = false, -- Experimental stage
        -- auto_set_highlight_group = true,
        -- auto_set_keymaps = true,
        -- auto_apply_diff_after_generation = false,
        enable_claude_text_editor_tool_mode = true, -- support_paste_from_clipboard = false,
        -- minimize_diff = true, -- Whether to remove unchanged lines when applying a code block
        enable_git_integration = false,
      },
      hints = { enabled = true },
      ---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | string
      provider = "claude", -- Recommend using Claude
      claude = {
        endpoint = "https://api.anthropic.com",
        -- model = "claude-3-5-sonnet-latest",
        model = "claude-3-5-sonnet-latest",
        temperature = 0,
        max_tokens = 4096,
      },
      copilot = {
        model = "claude-3.5-sonnet",
        temperature = 0,
        max_tokens = 8192,
      },
      ---Specify the special dual_boost mode
      ---1. enabled: Whether to enable dual_boost mode. Default to false.
      ---2. first_provider: The first provider to generate response. Default to "openai".
      ---3. second_provider: The second provider to generate response. Default to "claude".
      ---4. prompt: The prompt to generate response based on the two reference outputs.
      ---5. timeout: Timeout in milliseconds. Default to 60000.
      ---How it works:
      --- When dual_boost is enabled, avante will generate two responses from the first_provider and second_provider respectively. Then use the response from the first_provider as provider1_output and the response from the second_provider as provider2_output. Finally, avante will generate a response based on the prompt and the two reference outputs, with the default Provider as normal.
      ---Note: This is an experimental feature and may not work as expected.
      -- dual_boost = {
      --   enabled = false,
      --   first_provider = "cluade",
      --   second_provider = "copilot",
      --   prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
      --   timeout = 60000, -- Timeout in milliseconds
      -- },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    -- dynamically build it, taken from astronvim
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = {
          -- make sure rendering happens even without opening a markdown file first
          "yetone/avante.nvim",
        },
        opts = function(_, opts)
          opts.file_types = opts.file_types or { "markdown", "norg", "rmd", "org" }
          vim.list_extend(opts.file_types, { "Avante" })
        end,
      },
    },
  },
}
