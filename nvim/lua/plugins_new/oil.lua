return {
  src = "https://github.com/stevearc/oil.nvim",
  policy = { mode = "commit" },
  config = function()
    require("oil").setup({
      view_options = {
        show_hidden = true,
      },
    })

    vim.keymap.set("n", "<leader>fe", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    vim.keymap.set("n", "<leader>fE", function()
      local git_path = vim.fn.finddir(".git", ".;")
      local cd_git = vim.fn.fnamemodify(git_path, ":h")
      vim.cmd.edit(cd_git)
    end, { desc = "Open root directory" })
  end,
}
