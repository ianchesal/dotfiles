-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local util = require("lazyvim.util")
local wk = require("which-key")
local map = vim.keymap

-- Only set this up if we're in a tmux session
if os.getenv("TMUX") then
  map.del("n", "<C-h>")
  map.del("n", "<C-j>")
  map.del("n", "<C-k>")
  map.del("n", "<C-l>")
  map.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>")
  map.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>")
  map.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>")
  map.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>")
  vim.g.VimuxHeight = "30"
  vim.g.VimuxCloseOnExit = 1
end

-- I prefer different keymaps for Lazy and Mason and LSP interactions
map.del("n", "<leader>l")
-- Delete git keymaps. I use NeoGit. LazyVim only adds these if it
-- detects lazygit on the system.
if vim.fn.executable("lazygit") == 1 then
  map.del("n", "<leader>gg")
  map.del("n", "<leader>gG")
  map.del("n", "<leader>gl")
  map.del("n", "<leader>gL")
end

-- Tab to move to between buffers
if util.has("bufferline.nvim") then
  map.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
  map.set("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
else
  map.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
  map.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
end

-- Shift is a PIA to hit
vim.cmd([[nnoremap ; :]])

-- I am too old to re-learn how to yank and paste a whole line in vim
vim.cmd([[noremap Y Y]])

-- Allow me to typo q and w
vim.cmd([[
command -complete=file -bang -nargs=? W  :w<bang> <args>
command -complete=file -bang -nargs=? Wq :wq<bang> <args>
command -complete=file -bang -nargs=? Q :q<bang> <args>
command -complete=file -bang -nargs=? WQ :wq<bang> <args>
]])

wk.add({
  -- Neogit instead of LazyGit
  { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit" },
  { "<leader>gl", "<cmd>lua require('neogit').action('log', 'log_current')()<cr>", desc = "Neogit logs" },
  -- Plugin config is in ../plugins/diffview.lua
  { "<leader>gd", group = "Diffview" },
  { "<leader>gdc", "<cmd>DiffviewClose<cr>", mode = { "n", "i", "v" }, desc = "Close Diffview" },
  { "<leader>gdd", "<cmd>DiffviewOpen<cr>", mode = { "n", "i", "v" }, desc = "Open Diffview" },
  { "<leader>gdf", "<cmd>DiffviewToggleFiles<cr>", mode = { "n", "i", "v" }, desc = "Toggle Diffview file view" },
  {
    "<leader>gdh",
    "<cmd>DiffviewFileHistory<cr>",
    mode = { "n", "i", "v" },
    desc = "Toggle Diffview file history view",
  },
  { "<leader>gdr", "<cmd>DiffviewRefresh<cr>", mode = { "n", "i", "v" }, desc = "Refresh Diffview" },
  { "<leader>l", group = "lsp", icon = "" },
  { "<leader>lg", "<cmd>LspLog<cr>", desc = "Open LSP logs" },
  { "<leader>lh", "<cmd>LazyHealth<cr>", desc = "Health diagnostics" },
  { "<leader>li", "<cmd>LspInfo<cr>", desc = "Open LspInfo interface" },
  { "<leader>ll", "<cmd>Lazy<cr>", desc = "Open Lazy management interface" },
  { "<leader>lm", "<cmd>Mason<cr>", desc = "Open Mason management interface" },
  { "<leader>lr", "<cmd>LspRestart<cr>", desc = "Restart all LSPs" },
  { "<leader>uN", "<cmd>NoiceAll<cr>", desc = "Show all Noice notifications" },
  { "<leader>v", group = "vimux", icon = "" },
  { "<leader>vb", "<cmd>VimuxInterruptRunner<cr>", desc = "Interrupt command running in tmux shell" },
  { "<leader>vi", "<cmd>VimuxInspectRunner<cr>", desc = "Inspect tmux shell" },
  { "<leader>vk", "<cmd>VimuxCloseRunner<cr>", desc = "Close tmux shell" },
  { "<leader>vl", "<cmd>VimuxRunLastCommand<cr>", desc = "Run last shell command" },
  { "<leader>vp", "<cmd>VimuxPromptCommand<cr>", desc = "Run command in tmux shell" },
  { "<leader>vz", "<cmd>VimuxZoomRunner<cr>", desc = "Zoom tmux shell" },
})
