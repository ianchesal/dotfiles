-- nvim-mini/mini.diff — inline git diff signs (replaces gitsigns).
--
-- Sources:
--   - .snapshot/opts.lua [mini.diff]              — view.style, view.signs
--   - .snapshot/keys.lua [mini.diff]              — <leader>go toggle overlay
--   - LazyVim extras/editor/mini-diff.lua         — opts + toggle keymap
--
-- Note: lualine's diff segment reads vim.b.minidiff_summary (set by this
-- plugin); that source function is wired up in lualine.lua.
-- The Snacks.toggle for <leader>uG (mini-diff signs) from the extra is
-- omitted — it references LazyVim-specific Snacks toggle wiring and
-- vim.g.minidiff_disable which is a heavier integration than needed here.

return {
  src = "https://github.com/nvim-mini/mini.diff",
  policy = { mode = "commit" },
  config = function()
    require("mini.diff").setup({
      view = {
        style = "sign",
        signs = {
          add = "▎",
          change = "▎",
          delete = "",
        },
      },
    })

    vim.keymap.set("n", "<leader>go", function()
      require("mini.diff").toggle_overlay(0)
    end, { desc = "Toggle mini.diff overlay" })
  end,
}
