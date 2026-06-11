-- mfussenegger/nvim-lint — async linting via vim.diagnostic.
--
-- Sources:
--   - .snapshot/opts.lua [nvim-lint]                — linters_by_ft
--       (includes eslint/linting extras: dockerfile=hadolint,
--        fish, terraform, tf)
--   - LazyVim plugins/linting.lua at HEAD            — debounce + lint logic
--   - LazyVim plugins/extras/linting/eslint.lua      — eslint lsp-formatter
--       not ported (requires LazyVim.lsp.formatter util); eslint settings
--       go in lspconfig.lua instead
--
-- Debounced try_lint fires on BufWritePost, BufReadPost, InsertLeave.
-- linter.condition support and fallback/global linters inlined from LazyVim.

return {
  src = "https://github.com/mfussenegger/nvim-lint",
  policy = { mode = "commit" },
  config = function()
    local lint = require("lint")

    -- No custom linter overrides in the snapshot's linters table
    lint.linters_by_ft = {
      dockerfile = { "hadolint" },
      fish = { "fish" },
      terraform = { "terraform_validate" },
      tf = { "terraform_validate" },
    }

    local function do_lint()
      local names = lint._resolve_linter_by_ft(vim.bo.filetype)
      names = vim.list_extend({}, names)

      if #names == 0 then
        vim.list_extend(names, lint.linters_by_ft["_"] or {})
      end
      vim.list_extend(names, lint.linters_by_ft["*"] or {})

      local ctx = { filename = vim.api.nvim_buf_get_name(0) }
      ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
      names = vim.tbl_filter(function(name)
        local linter = lint.linters[name]
        return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
      end, names)

      if #names > 0 then
        lint.try_lint(names)
      end
    end

    local timer = vim.uv.new_timer()
    local function debounced_lint()
      timer:start(100, 0, function()
        timer:stop()
        vim.schedule(do_lint)
      end)
    end

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
      callback = debounced_lint,
    })
  end,
}
