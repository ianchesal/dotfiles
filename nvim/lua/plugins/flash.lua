-- folke/flash.nvim — fast cursor navigation with labels.
--
-- Sources:
--   - .snapshot/opts.lua [flash.nvim]   — no custom opts (empty table)
--   - .snapshot/keys.lua [flash.nvim]   — all 6 keymaps
--   - LazyVim plugins/editor.lua        — flash block (key bodies)
--
-- All keymaps from snapshot ported:
--   s        (n/x/o) — Flash jump
--   S        (n/o/x) — Flash Treesitter
--   r        (o)     — Remote Flash
--   R        (o/x)   — Treesitter Search
--   <c-s>    (c)     — Toggle Flash Search
--   <c-space> (n/o/x) — Treesitter Incremental Selection

return {
  src = "https://github.com/folke/flash.nvim",
  policy = { mode = "commit" },
  config = function()
    require("flash").setup({})

    vim.keymap.set({ "n", "x", "o" }, "s", function()
      require("flash").jump()
    end, { desc = "Flash" })

    vim.keymap.set({ "n", "o", "x" }, "S", function()
      require("flash").treesitter()
    end, { desc = "Flash Treesitter" })

    vim.keymap.set("o", "r", function()
      require("flash").remote()
    end, { desc = "Remote Flash" })

    vim.keymap.set({ "o", "x" }, "R", function()
      require("flash").treesitter_search()
    end, { desc = "Treesitter Search" })

    vim.keymap.set("c", "<c-s>", function()
      require("flash").toggle()
    end, { desc = "Toggle Flash Search" })

    vim.keymap.set({ "n", "o", "x" }, "<c-space>", function()
      require("flash").treesitter()
    end, { desc = "Treesitter Incremental Selection" })
  end,
}
