return {
  src = "https://github.com/folke/sidekick.nvim",
  policy = { mode = "commit" },
  config = function()
    require("sidekick").setup({
      nes = {
        -- Disables "next edit suggestions" -- I don't like this feature
        enabled = false,
      },
      cli = {
        mux = {
          enabled = true,
          create = "split",
          split = {
            size = 0.3,
          },
        },
      },
    })

    -- Keymaps from LazyVim's ai.sidekick extra
    -- (the extra also added a <Tab> expr-map for NES; intentionally not
    -- ported since NES is disabled above)
    vim.keymap.set({ "n", "v" }, "<leader>a", "", { desc = "+ai" })
    vim.keymap.set({ "n", "t", "i", "x" }, "<c-.>", function()
      require("sidekick.cli").focus()
    end, { desc = "Sidekick Focus" })
    vim.keymap.set("n", "<leader>aa", function()
      require("sidekick.cli").toggle()
    end, { desc = "Sidekick Toggle CLI" })
    vim.keymap.set("n", "<leader>as", function()
      require("sidekick.cli").select()
    end, { desc = "Select CLI" })
    vim.keymap.set("n", "<leader>ad", function()
      require("sidekick.cli").close()
    end, { desc = "Detach a CLI Session" })
    vim.keymap.set({ "x", "n" }, "<leader>at", function()
      require("sidekick.cli").send({ msg = "{this}" })
    end, { desc = "Send This" })
    vim.keymap.set("n", "<leader>af", function()
      require("sidekick.cli").send({ msg = "{file}" })
    end, { desc = "Send File" })
    vim.keymap.set("x", "<leader>av", function()
      require("sidekick.cli").send({ msg = "{selection}" })
    end, { desc = "Send Visual Selection" })
    vim.keymap.set({ "n", "x" }, "<leader>ap", function()
      require("sidekick.cli").prompt()
    end, { desc = "Sidekick Select Prompt" })
  end,
}
