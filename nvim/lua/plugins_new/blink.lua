-- Saghen/blink.cmp — completion engine, priority 40.
-- Policy: tag (blink ships semver releases; LazyVim tracked with version="*").
--
-- Sources:
--   - .snapshot/opts.lua [blink.cmp]       — resolved merged opts
--   - LazyVim plugins/coding.lua at HEAD   — base opts + snippets.expand
--   - nvim/lua/plugins/blink.lua           — user overrides (win on conflicts):
--       enabled(), completion.list.selection, full keymap table, Tab chains
--
-- Dropped: opts_extend (lazy.nvim idiom).
-- lazydev source wired here (per_filetype.lua = lazydev inherit_defaults).
-- Native snippet expand: vim.snippet.expand (no LazyVim util layer).

return {
  src = "https://github.com/Saghen/blink.cmp",
  policy = { mode = "tag" },
  priority = 40,
  config = function()
    require("blink.cmp").setup({
      -- User override: disable in prompt buffers, macro replay, comment nodes
      enabled = function()
        local disabled = false
        local success, node = pcall(vim.treesitter.get_node)
        disabled = disabled or (vim.bo.buftype == "prompt")
        disabled = disabled or (vim.fn.reg_recording() ~= "")
        disabled = disabled or (vim.fn.reg_executing() ~= "")
        disabled = disabled
          or (success and node ~= nil and vim.tbl_contains({ "comment", "line_comment", "block_comment" }, node:type()))
        return not disabled
      end,

      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
        kind_icons = {
          Array = " ",
          Boolean = "󰨙 ",
          Class = " ",
          Codeium = "󰘦 ",
          Collapsed = " ",
          Color = " ",
          Constant = "󰏿 ",
          Constructor = " ",
          Control = " ",
          Copilot = " ",
          Enum = " ",
          EnumMember = " ",
          Event = " ",
          Field = " ",
          File = " ",
          Folder = " ",
          Function = "󰊕 ",
          Interface = " ",
          Key = " ",
          Keyword = " ",
          Method = "󰊕 ",
          Module = " ",
          Namespace = "󰦮 ",
          Null = " ",
          Number = "󰎠 ",
          Object = " ",
          Operator = " ",
          Package = " ",
          Property = " ",
          Reference = " ",
          Snippet = "󱄽 ",
          String = " ",
          Struct = "󰆼 ",
          Supermaven = " ",
          TabNine = "󰏚 ",
          Text = " ",
          TypeParameter = " ",
          Unit = " ",
          Value = " ",
          Variable = "󰀫 ",
        },
      },

      snippets = {
        preset = "default",
        -- Use native Neovim snippet expansion (no LazyVim util layer)
        expand = function(snippet)
          vim.snippet.expand(snippet)
        end,
      },

      completion = {
        accept = {
          auto_brackets = { enabled = true },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        ghost_text = { enabled = true },
        -- User override: prevent accidental <CR> selection at line end
        list = { selection = { preselect = false, auto_insert = true } },
        menu = {
          draw = {
            treesitter = { "lsp" },
          },
        },
      },

      cmdline = {
        enabled = true,
        keymap = {
          preset = "cmdline",
          ["<Left>"] = false,
          ["<Right>"] = false,
        },
        completion = {
          ghost_text = { enabled = true },
          list = { selection = { preselect = false } },
          menu = {
            auto_show = function(ctx)
              return ctx.mode ~= "/"
            end,
          },
        },
      },

      -- User keymap (overrides LazyVim defaults; Tab chain: snippet→sidekick→inline)
      keymap = {
        preset = "enter",
        ["<Tab>"] = {
          "snippet_forward",
          function() -- sidekick next-edit suggestion
            return require("sidekick").nes_jump_or_apply()
          end,
          function() -- native inline completions (Neovim 0.11+)
            if vim.lsp.inline_completion then
              return vim.lsp.inline_completion.get()
            end
          end,
          "fallback",
        },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-N>"] = { "select_next", "show" },
        ["<C-P>"] = { "select_prev", "show" },
        ["<C-J>"] = { "select_next", "fallback" },
        ["<C-K>"] = { "select_prev", "fallback" },
        ["<C-U>"] = { "scroll_documentation_up", "fallback" },
        ["<C-D>"] = { "scroll_documentation_down", "fallback" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<C-y>"] = { "select_and_accept" },
        ["<CR>"] = { "accept", "fallback" },
      },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
        per_filetype = {
          lua = { "lazydev", inherit_defaults = true },
        },
      },
    })
  end,
}
