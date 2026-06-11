-- folke/trouble.nvim — pretty diagnostics, references, telescope results,
-- quickfix and location list.
--
-- Sources:
--   - .snapshot/opts.lua [trouble.nvim]  — modes.lsp.win.position = "right"
--   - LazyVim editor.lua at HEAD          — trouble block (keymap bodies)
--   - .snapshot/keys.lua [trouble.nvim]  — all keymaps (with [q/]q bodies)
--   - Old user keymaps.lua               — <leader>xC clear-quickfix

return {
  src = "https://github.com/folke/trouble.nvim",
  policy = { mode = "commit" },
  config = function()
    require("trouble").setup({
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    })

    -- ── Keymaps ──────────────────────────────────────────────────────────

    vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
    vim.keymap.set(
      "n",
      "<leader>xX",
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      { desc = "Buffer Diagnostics (Trouble)" }
    )
    vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols (Trouble)" })
    vim.keymap.set(
      "n",
      "<leader>cS",
      "<cmd>Trouble lsp toggle<cr>",
      { desc = "LSP references/definitions/... (Trouble)" }
    )
    vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
    vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

    -- Trouble-aware quickfix navigation: prefer trouble when open, else
    -- fall through to the normal :cprev/:cnext. Bodies from LazyVim editor.lua.
    vim.keymap.set("n", "[q", function()
      if require("trouble").is_open() then
        require("trouble").prev({ skip_groups = true, jump = true })
      else
        local ok, err = pcall(vim.cmd.cprev)
        if not ok then
          vim.notify(err, vim.log.levels.ERROR)
        end
      end
    end, { desc = "Previous Trouble/Quickfix Item" })
    vim.keymap.set("n", "]q", function()
      if require("trouble").is_open() then
        require("trouble").next({ skip_groups = true, jump = true })
      else
        local ok, err = pcall(vim.cmd.cnext)
        if not ok then
          vim.notify(err, vim.log.levels.ERROR)
        end
      end
    end, { desc = "Next Trouble/Quickfix Item" })

    -- User keymap: clear quickfix list (from old keymaps.lua <leader>xC)
    vim.keymap.set("n", "<leader>xC", "<cmd>cexpr []<cr>", { desc = "Clear Quickfix list" })
  end,
}
