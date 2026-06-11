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
-- prettier.condition: inlined from LazyVim prettier extra (has_parser check).
-- vim.g.lazyvim_prettier_needs_config not carried forward (always false default).

return {
  src = "https://github.com/stevearc/conform.nvim",
  policy = { mode = "commit" },
  config = function()
    -- Prettier condition: check if prettier can handle the buffer
    -- (inlined from LazyVim extras/formatting/prettier.lua)
    local prettier_supported = {
      "css",
      "graphql",
      "handlebars",
      "html",
      "javascript",
      "javascriptreact",
      "json",
      "jsonc",
      "less",
      "markdown",
      "markdown.mdx",
      "scss",
      "typescript",
      "typescriptreact",
      "vue",
      "yaml",
    }

    local prettier_has_parser_cache = {}
    local function prettier_has_parser(ctx)
      if prettier_has_parser_cache[ctx.filename] ~= nil then
        return prettier_has_parser_cache[ctx.filename]
      end
      local ft = vim.bo[ctx.buf].filetype
      if vim.tbl_contains(prettier_supported, ft) then
        prettier_has_parser_cache[ctx.filename] = true
        return true
      end
      local ret = vim.fn.system({ "prettier", "--file-info", ctx.filename })
      local ok, parser = pcall(function()
        return vim.fn.json_decode(ret).inferredParser
      end)
      local result = ok and parser and parser ~= vim.NIL
      prettier_has_parser_cache[ctx.filename] = result
      return result
    end

    require("conform").setup({
      default_format_opts = {
        timeout_ms = 3000,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },

      formatters_by_ft = {
        css = { "prettier" },
        eruby = { "erb_format" },
        fish = { "fish_indent" },
        graphql = { "prettier" },
        handlebars = { "prettier" },
        hcl = { "packer_fmt" },
        html = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        less = { "prettier" },
        lua = { "stylua" },
        markdown = { "prettier" },
        ["markdown.mdx"] = { "prettier" },
        ruby = { "rubocop" },
        scss = { "prettier" },
        sh = { "shfmt" },
        terraform = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },
        tf = { "terraform_fmt" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        yaml = { "prettier" },
      },

      formatters = {
        injected = {
          options = { ignore_errors = true },
        },
        prettier = {
          condition = function(_, ctx)
            return prettier_has_parser(ctx)
          end,
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
