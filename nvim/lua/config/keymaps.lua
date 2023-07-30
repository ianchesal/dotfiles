-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Unmap mappings used by tmux plugin
--
-- TODO(ian): There's likely a better way to do this.
-- Only switch to TMuxNavgivate if we're in a tmux session

local Util = require("lazyvim.util")

vim.keymap.del("n", "<C-h>")
vim.keymap.del("n", "<C-j>")
vim.keymap.del("n", "<C-k>")
vim.keymap.del("n", "<C-l>")
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>")
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>")
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>")

-- Only set this up if we're in a tmux session
if os.getenv("TMUX") then
  vim.keymap.set("n", "<leader>vp", ":VimuxPromptCommand<cr>", { desc = "Run command in tmux shell" })
  vim.keymap.set("n", "<leader>vl", ":VimuxRunLastCommand<cr>", { desc = "Run last shell command" })
  vim.keymap.set("n", "<leader>vi", ":VimuxInspectRunner<cr>", { desc = "Inspect tmux shell" })
  vim.keymap.set("n", "<leader>vz", ":VimuxZoomRunner<cr>", { desc = "Zoom tmux shell" })
  vim.keymap.set("n", "<leader>vk", ":VimuxCloseRunner<cr>", { desc = "Close tmux shell" })
  vim.keymap.set("n", "<leader>vb", ":VimuxInterruptRunner<cr>", { desc = "Interrupt command running in tmux shell" })
  vim.g.VimuxHeight = "30"
  vim.g.VimuxCloseOnExit = 1
end

-- I prefer these keymaps for Lazy and Mason and LSP interactions
vim.keymap.del("n", "<leader>l")
-- vim.keymap.del("n", "<leader>cl")
vim.keymap.set("n", "<leader>lg", ":LspLog<cr>", { desc = "Open LSP logs" })
vim.keymap.set("n", "<leader>li", ":LspInfo<cr>", { desc = "Open LspInfo interface" })
vim.keymap.set("n", "<leader>ll", ":Lazy<cr>", { desc = "Open Lazy management interface" })
vim.keymap.set("n", "<leader>lm", ":Mason<cr>", { desc = "Open Mason management interface" })
vim.keymap.set("n", "<leader>ln", "<cmd>NullLsInfo<CR>", { desc = "NullLS Information" })
vim.keymap.set("n", "<leader>lr", ":LspRestart<cr>", { desc = "Restart LSP" })

-- MarkdownPreview
vim.keymap.set("n", "<leader>mp", ":MarkdownPreviewToggle<cr>", { desc = "Toggle Markdown preview" })

-- Tab to move to between buffers
if Util.has("bufferline.nvim") then
  vim.keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
  vim.keymap.set("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
else
  vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
  vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
end

-- I am too old to re-learn how to yank and paste a whole line in vim
vim.cmd([[noremap Y Y]])

-- Allow me to typo q and w
vim.cmd([[
cnoreabbrev <expr> W ((getcmdtype() is# ':' && getcmdline() is# 'W')?('w'):('W'))
cnoreabbrev <expr> Q ((getcmdtype() is# ':' && getcmdline() is# 'Q')?('q'):('Q'))
cnoreabbrev <expr> WQ ((getcmdtype() is# ':' && getcmdline() is# 'WQ')?('wq'):('WQ'))
cnoreabbrev <expr> Wq ((getcmdtype() is# ':' && getcmdline() is# 'Wq')?('wq'):('Wq'))
]])
