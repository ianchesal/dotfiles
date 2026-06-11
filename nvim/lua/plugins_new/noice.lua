-- folke/noice.nvim — highly experimental UI replacement for messages,
-- cmdline and the popupmenu.
--
-- Sources:
--   - .snapshot/opts.lua [noice.nvim]  — resolved merged opts (routes, lsp
--     overrides, presets)
--   - LazyVim ui.lua at HEAD — noice block (routes resolved from source)
--   - .snapshot/keys.lua [noice.nvim]  — all keymaps
--   - Old user keymaps.lua             — <leader>uN → NoiceAll

return {
  src = "https://github.com/folke/noice.nvim",
  policy = { mode = "commit" },
  config = function()
    require("noice").setup({
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          view = "mini",
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
    })

    -- ── Keymaps ──────────────────────────────────────────────────────────

    -- Group label
    vim.keymap.set("n", "<leader>sn", "", { desc = "+noice" })

    -- Cmdline redirect to split (mode = "c")
    vim.keymap.set("c", "<S-Enter>", function()
      require("noice").redirect(vim.fn.getcmdline())
    end, { desc = "Redirect Cmdline" })

    -- Noice message pickers
    vim.keymap.set("n", "<leader>snl", function()
      require("noice").cmd("last")
    end, { desc = "Noice Last Message" })
    vim.keymap.set("n", "<leader>snh", function()
      require("noice").cmd("history")
    end, { desc = "Noice History" })
    vim.keymap.set("n", "<leader>sna", function()
      require("noice").cmd("all")
    end, { desc = "Noice All" })
    vim.keymap.set("n", "<leader>snd", function()
      require("noice").cmd("dismiss")
    end, { desc = "Dismiss All" })
    vim.keymap.set("n", "<leader>snt", function()
      require("noice").cmd("pick")
    end, { desc = "Noice Picker (Telescope/FzfLua)" })

    -- LSP doc scroll — expr maps so the key falls through when noice is not active
    vim.keymap.set({ "i", "n", "s" }, "<c-f>", function()
      if not require("noice.lsp").scroll(4) then
        return "<c-f>"
      end
    end, { silent = true, expr = true, desc = "Scroll Forward" })
    vim.keymap.set({ "i", "n", "s" }, "<c-b>", function()
      if not require("noice.lsp").scroll(-4) then
        return "<c-b>"
      end
    end, { silent = true, expr = true, desc = "Scroll Backward" })

    -- User keymap: show full notification history (old keymaps.lua <leader>uN)
    vim.keymap.set("n", "<leader>uN", "<cmd>NoiceAll<cr>", { desc = "Show all Noice notifications" })
  end,
}
