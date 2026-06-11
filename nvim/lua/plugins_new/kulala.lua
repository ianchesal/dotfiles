-- mistweaverco/kulala.nvim — REST client for .http files.
--
-- Sources:
--   - .snapshot/keys.lua [kulala.nvim]             — 14 keymaps
--   - LazyVim extras/util/rest.lua at HEAD          — filetype detection + opts
--
-- ft-scoped keys: <leader>R group is global (any filetype); all other
-- kulala keys are scoped to http filetype via FileType autocmd with
-- buffer-local maps (same pattern as markdown-preview.lua).
-- <leader>Rr (replay) and <leader>Rb (scratchpad) are global (no ft=http).
-- vim.filetype.add for http extension is done here (from LazyVim rest extra).

return {
  src = "mistweaverco/kulala.nvim",
  policy = { mode = "commit" },
  config = function()
    -- Register .http extension as http filetype
    vim.filetype.add({
      extension = {
        http = "http",
      },
    })

    require("kulala").setup({})

    -- Global keymaps (not ft-scoped)
    vim.keymap.set("n", "<leader>R", "", { desc = "+Rest" })
    vim.keymap.set("n", "<leader>Rb", "<cmd>lua require('kulala').scratchpad()<cr>", { desc = "Open scratchpad" })
    vim.keymap.set("n", "<leader>Rr", "<cmd>lua require('kulala').replay()<cr>", { desc = "Replay the last request" })

    -- ft-scoped keymaps for http buffers
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("kulala_http_keys", { clear = true }),
      pattern = "http",
      callback = function(ev)
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
        end
        map("<leader>Rc", "<cmd>lua require('kulala').copy()<cr>", "Copy as cURL")
        map("<leader>RC", "<cmd>lua require('kulala').from_curl()<cr>", "Paste from curl")
        map("<leader>Re", "<cmd>lua require('kulala').set_selected_env()<cr>", "Set environment")
        map("<leader>Rg", "<cmd>lua require('kulala').download_graphql_schema()<cr>", "Download GraphQL schema")
        map("<leader>Ri", "<cmd>lua require('kulala').inspect()<cr>", "Inspect current request")
        map("<leader>Rn", "<cmd>lua require('kulala').jump_next()<cr>", "Jump to next request")
        map("<leader>Rp", "<cmd>lua require('kulala').jump_prev()<cr>", "Jump to previous request")
        map("<leader>Rq", "<cmd>lua require('kulala').close()<cr>", "Close window")
        map("<leader>Rs", "<cmd>lua require('kulala').run()<cr>", "Send the request")
        map("<leader>RS", "<cmd>lua require('kulala').show_stats()<cr>", "Show stats")
        map("<leader>Rt", "<cmd>lua require('kulala').toggle_view()<cr>", "Toggle headers/body")
      end,
    })
  end,
}
