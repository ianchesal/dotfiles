-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Unmap mappings used by tmux plugin
--
-- TODO(ian): There's likely a better way to do this.
vim.keymap.del("n", "<C-h>")
vim.keymap.del("n", "<C-j>")
vim.keymap.del("n", "<C-k>")
vim.keymap.del("n", "<C-l>")
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>")
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>")
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>")
vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>")

vim.keymap.set("n", "<leader>vp", ":VimuxPromptCommand<cr>", { desc = "Run command in tmux shell" })
vim.keymap.set("n", "<leader>vl", ":VimuxRunLastCommand<cr>", { desc = "Run last shell command" })
vim.keymap.set("n", "<leader>vi", ":VimuxInspectRunner<cr>", { desc = "Inspect tmux shell" })
vim.keymap.set("n", "<leader>vz", ":VimuxZoomRunner<cr>", { desc = "Zoom tmux shell" })
vim.keymap.set("n", "<leader>vk", ":VimuxCloseRunner<cr>", { desc = "Close tmux shell" })
vim.keymap.set("n", "<leader>vb", ":VimuxInterruptRunner<cr>", { desc = "Interrupt command running in tmux shell" })
vim.g.VimuxHeight = "30"
vim.g.VimuxCloseOnExit = 1
