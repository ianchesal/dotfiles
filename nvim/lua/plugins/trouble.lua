return {
  "folke/trouble.nvim",
  cmd = { "TroubleToggle", "Trouble" },
  opts = { use_diagnostic_signs = true },
  keys = {
    { "<leader>tt", "<cmd>TroubleToggle document_diagnostics<cr>",  desc = "Show document diagnostics" },
    { "<leader>tw", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Show workspace diagnostics" },
    { "<leader>tl", "<cmd>TroubleToggle loclist<cr>",               desc = "Show location list" },
    { "<leader>tu", "<cmd>TroubleToggle quickfix<cr>",              desc = "Show quickfix list" },
    {
      "[q",
      function()
        if require("trouble").is_open() then
          require("trouble").previous({ skip_groups = true, jump = true })
        else
          local ok, result = pcall(vim.cmd, "cprev")
          if not ok then
            ok, result = pcall(vim.cmd, "clast")
            if not ok then
              print("No errors")
            end
          end
        end
      end,
      desc = "Previous trouble/quickfix item",
    },
    {
      "]q",
      function()
        if require("trouble").is_open() then
          require("trouble").next({ skip_groups = true, jump = true })
        else
          local ok, result = pcall(vim.cmd, "cnext")
          if not ok then
            ok, result = pcall(vim.cmd, "cfirst")
            if not ok then
              print("No errors")
            end
          end
        end
      end,
      desc = "Next trouble/quickfix item",
    },
  },
}
