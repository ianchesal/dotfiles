return {
  src = "https://github.com/christoomey/vim-tmux-navigator",
  policy = { mode = "commit" },
  config = function()
    vim.keymap.set("n", "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>")
    vim.keymap.set("n", "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>")
    vim.keymap.set("n", "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>")
    vim.keymap.set("n", "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>")
  end,
}
