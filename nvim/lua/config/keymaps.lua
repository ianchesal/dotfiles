-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local util = require("lazyvim.util")
local wk = require("which-key")
local map = vim.keymap

-- Don't use Snacks.terminal() -- I'm a tmux person
map.del("n", "<leader>fT")
map.del("n", "<leader>ft")
map.del("n", "<c-/>")
map.del("n", "<c-_>")
-- map.del("t", "<C-/>")
-- map.del("t", "<C-_>")

-- I prefer different keymaps for Lazy and Mason and LSP interactions
map.del("n", "<leader>l")
wk.add({
  { "<leader>l", group = "lsp", icon = "" },
  { "<leader>lg", "<cmd>LspLog<cr>", desc = "Open LSP logs" },
  { "<leader>lh", "<cmd>LazyHealth<cr>", desc = "Health diagnostics" },
  { "<leader>li", "<cmd>LspInfo<cr>", desc = "Open LspInfo interface" },
  { "<leader>ll", "<cmd>Lazy<cr>", desc = "Open Lazy management interface" },
  { "<leader>lm", "<cmd>Mason<cr>", desc = "Open Mason management interface" },
  { "<leader>lr", "<cmd>LspRestart<cr>", desc = "Restart all LSPs" },
})

-- Use Oil.nvim for filesystem stuff
map.set("n", "<leader>fe", "<CMD>Oil<CR>", { desc = "Open parent directory" })
map.set("n", "<leader>fE", function()
  local git_path = vim.fn.finddir(".git", ".;")
  local cd_git = vim.fn.fnamemodify(git_path, ":h")
  vim.api.nvim_command(string.format("edit %s", cd_git))
end, { desc = "Open root directory" })

-- Delete git keymaps. I use NeoGit. LazyVim only adds these if it
-- detects lazygit on the system.
if vim.fn.executable("lazygit") == 1 then
  map.del("n", "<leader>gg")
  map.del("n", "<leader>gG")
  map.del("n", "<leader>gl")
  map.del("n", "<leader>gL")
  map.del("n", "<leader>gY")
  map.del("n", "<leader>gS")
end
wk.add({
  -- Neogit instead of LazyGit
  -- Plugin config is in ../plugins/neogit.lua
  { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit" },
  {
    "<leader>gl",
    "<cmd>lua require('neogit').action('log', 'log_current')()<cr>",
    desc = "Neogit logs (buffer)",
  },

  -- Diffview for working with diffs
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
})

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

-- This let's me do ycc to comment current line out but duplicate it as well
-- Works with a prefix number to yank-comment-copy more than one line.
map.set("n", "ycc", '"yy" . v:count1 . "gcc\']p"', { remap = true, expr = true, desc = "yank-comment-copy" })

-- Allow me to typo q and w
vim.cmd([[
command -complete=file -bang -nargs=? W  :w<bang> <args>
command -complete=file -bang -nargs=? Wq :wq<bang> <args>
command -complete=file -bang -nargs=? Q :q<bang> <args>
command -complete=file -bang -nargs=? WQ :wq<bang> <args>
]])

wk.add({
  -- Trouble/Quickfix addtional shortcuts
  {
    "<leader>xC",
    "<cmd>cexpr []<cr>",
    desc = "Clear Quickfix list",
    icon = "󰶦",
  },

  -- Noice
  -- Handy for seeing errors that disappear too quickly
  { "<leader>uN", "<cmd>NoiceAll<cr>", desc = "Show all Noice notifications" },
})
