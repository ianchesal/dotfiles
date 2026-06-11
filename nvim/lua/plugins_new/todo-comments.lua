-- folke/todo-comments.nvim — highlight and search TODO/HACK/BUG etc comments.
--
-- Sources:
--   - .snapshot/opts.lua [todo-comments.nvim]  — empty opts (defaults only)
--   - LazyVim editor.lua at HEAD                — todo block (base keymaps)
--   - LazyVim extras/editor/snacks_picker.lua   — snacks overrides for <leader>st/<leader>sT
--   - .snapshot/keys.lua [todo-comments.nvim]   — all keymaps
--
-- Note: the snapshot contains both a Telescope version and a Snacks version
-- of <leader>st/<leader>sT.  The Snacks version wins (snacks_picker extra).

return {
  src = "https://github.com/folke/todo-comments.nvim",
  policy = { mode = "commit" },
  config = function()
    require("todo-comments").setup({})

    -- ── Keymaps ──────────────────────────────────────────────────────────

    -- Navigation
    vim.keymap.set("n", "]t", function()
      require("todo-comments").jump_next()
    end, { desc = "Next Todo Comment" })
    vim.keymap.set("n", "[t", function()
      require("todo-comments").jump_prev()
    end, { desc = "Previous Todo Comment" })

    -- Trouble integration
    vim.keymap.set("n", "<leader>xt", "<cmd>Trouble todo toggle<cr>", { desc = "Todo (Trouble)" })
    vim.keymap.set(
      "n",
      "<leader>xT",
      "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>",
      { desc = "Todo/Fix/Fixme (Trouble)" }
    )

    -- Snacks picker (snacks_picker extra overrides the Telescope defaults)
    vim.keymap.set("n", "<leader>st", function()
      Snacks.picker.todo_comments()
    end, { desc = "Todo" })
    vim.keymap.set("n", "<leader>sT", function()
      Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
    end, { desc = "Todo/Fix/Fixme" })
  end,
}
