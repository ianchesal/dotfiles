-- stevearc/conform.nvim — format engine.
--
-- Sources:
--   - .snapshot/opts.lua [conform.nvim]             — resolved merged opts incl.
--       prettier extra wiring (formatters_by_ft + prettier.condition)
--   - LazyVim plugins/formatting.lua at HEAD         — format-on-save pattern
--   - LazyVim plugins/extras/formatting/prettier.lua — condition logic inlined
--   - .snapshot/keys.lua [conform.nvim]             — <leader>cF keymap
--
-- format-on-save: BufWritePre autocmd that checks vim.b.autoformat /
-- vim.g.autoformat gates — replicates LazyVim.format.enabled() behavior
-- without the LazyVim util layer.
--
-- prettier (and its has_parser condition) dropped October 2026 with the npm
-- trim; yaml now formats through yamlls via lsp_format = "fallback".
-- vim.g.lazyvim_prettier_needs_config not carried forward (always false default).

return {
  src = "https://github.com/stevearc/conform.nvim",
  policy = { mode = "commit" },
  config = function()
    require("conform").setup({
      default_format_opts = {
        timeout_ms = 3000,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },

      formatters_by_ft = {
        fish = { "fish_indent" },
        hcl = { "packer_fmt" },
        lua = { "stylua" },
        sh = { "shfmt" },
        terraform = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },
        tf = { "terraform_fmt" },
      },

      formatters = {
        injected = {
          options = { ignore_errors = true },
        },
      },
    })

    -- Format on save: respects vim.b.autoformat (buffer) and vim.g.autoformat (global)
    -- Mirrors LazyVim.format.enabled() logic without the util layer.
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("conform_format_on_save", { clear = true }),
      callback = function(ev)
        local buf = ev.buf
        local baf = vim.b[buf].autoformat
        local gaf = vim.g.autoformat
        -- buffer-local value takes precedence; global defaults to true.
        -- NOTE: must be an explicit nil-check, not `baf ~= nil and baf or ...`
        -- — a buffer-local `false` (e.g. markdown) must NOT fall through to
        -- the global.
        local enabled
        if baf ~= nil then
          enabled = baf
        else
          enabled = gaf == nil or gaf
        end
        if enabled then
          require("conform").format({ bufnr = buf })
        end
      end,
    })

    -- Format injected languages (e.g. lua blocks in markdown)
    vim.keymap.set({ "n", "x" }, "<leader>cF", function()
      require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
    end, { desc = "Format Injected Langs" })

    -- Format current buffer (conform with LSP fallback)
    vim.keymap.set({ "n", "x" }, "<leader>cf", function()
      require("conform").format({ async = true, lsp_format = "fallback" })
    end, { desc = "Format" })
  end,
}
