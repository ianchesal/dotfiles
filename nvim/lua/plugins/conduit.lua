return {
  "kitallen23/conduit.nvim",
  config = function()
    local conduit = require("conduit")
    local keymap = vim.keymap
    -- vim.g.conduit_opts = {
    --   -- Put your options here
    -- }

    keymap.set("n", "<leader>ai", function()
      conduit.ask()
    end, { desc = "Generate conduit prompt" })
    keymap.set("n", "<leader>ac", function()
      conduit.ask("@cursor: ")
    end, { desc = "Generate conduit prompt at cursor" })
    keymap.set("v", "<leader>ai", function()
      conduit.ask("@selection: ")
    end, { desc = "Generate conduit prompt about selection" })
    keymap.set({ "n", "v" }, "<leader>ap", function()
      conduit.select_prompt()
    end, { desc = "Select conduit prompt" })
    keymap.set("n", "<leader>ad", function()
      conduit.select_prompt("fix_line")
    end, { desc = "Get diagnostic prompt" })
  end,
}
