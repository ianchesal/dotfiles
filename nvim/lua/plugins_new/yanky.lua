-- gbprod/yanky.nvim — extended yank/paste with history ring.
--
-- Sources:
--   - .snapshot/opts.lua [yanky.nvim]              — highlight.timer, system_clipboard
--   - .snapshot/keys.lua [yanky.nvim]              — full keymap set (19 maps)
--   - LazyVim extras/util/yanky.lua at HEAD         — picker + key bodies
--
-- <leader>p: open yank history via Snacks.picker.yanky() (snacks picker
-- variant from LazyVim yanky extra; picker.name check dropped, Snacks is
-- the only picker in this setup).
--
-- system_clipboard.sync_with_ring set to false (snapshot value; LazyVim
-- default uses SSH_CONNECTION detection — overridden to always false here).

return {
  src = "https://github.com/gbprod/yanky.nvim",
  policy = { mode = "commit" },
  config = function()
    require("yanky").setup({
      system_clipboard = {
        sync_with_ring = false,
      },
      highlight = {
        timer = 150,
      },
    })

    -- Open yank history in Snacks picker
    vim.keymap.set({ "n", "x" }, "<leader>p", function()
      Snacks.picker.yanky()
    end, { desc = "Open Yank History" })

    -- Core yank/put maps
    vim.keymap.set({ "n", "x" }, "y", "<Plug>(YankyYank)", { desc = "Yank Text" })
    vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Put Text After Cursor" })
    vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)", { desc = "Put Text Before Cursor" })
    vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", { desc = "Put Text After Selection" })
    vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", { desc = "Put Text Before Selection" })

    -- Cycle through yank history
    vim.keymap.set("n", "[y", "<Plug>(YankyCycleForward)", { desc = "Cycle Forward Through Yank History" })
    vim.keymap.set("n", "]y", "<Plug>(YankyCycleBackward)", { desc = "Cycle Backward Through Yank History" })

    -- Linewise indented put
    vim.keymap.set("n", "]p", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "Put Indented After Cursor (Linewise)" })
    vim.keymap.set(
      "n",
      "[p",
      "<Plug>(YankyPutIndentBeforeLinewise)",
      { desc = "Put Indented Before Cursor (Linewise)" }
    )
    vim.keymap.set("n", "]P", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "Put Indented After Cursor (Linewise)" })
    vim.keymap.set(
      "n",
      "[P",
      "<Plug>(YankyPutIndentBeforeLinewise)",
      { desc = "Put Indented Before Cursor (Linewise)" }
    )

    -- Shift-indented put
    vim.keymap.set("n", ">p", "<Plug>(YankyPutIndentAfterShiftRight)", { desc = "Put and Indent Right" })
    vim.keymap.set("n", "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", { desc = "Put and Indent Left" })
    vim.keymap.set("n", ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", { desc = "Put Before and Indent Right" })
    vim.keymap.set("n", "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", { desc = "Put Before and Indent Left" })

    -- Filter put
    vim.keymap.set("n", "=p", "<Plug>(YankyPutAfterFilter)", { desc = "Put After Applying a Filter" })
    vim.keymap.set("n", "=P", "<Plug>(YankyPutBeforeFilter)", { desc = "Put Before Applying a Filter" })
  end,
}
