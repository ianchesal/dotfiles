-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Unmap mappings used by tmux plugin
--
-- TODO(ian): There's likely a better way to do this.
-- Only switch to TMuxNavgivate if we're in a tmux session

local Util = require("lazyvim.util")
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

  map.set("n", "<leader>vp", ":VimuxPromptCommand<cr>", { desc = "Run command in tmux shell" })
  map.set("n", "<leader>vl", ":VimuxRunLastCommand<cr>", { desc = "Run last shell command" })
  map.set("n", "<leader>vi", ":VimuxInspectRunner<cr>", { desc = "Inspect tmux shell" })
  map.set("n", "<leader>vz", ":VimuxZoomRunner<cr>", { desc = "Zoom tmux shell" })
  map.set("n", "<leader>vk", ":VimuxCloseRunner<cr>", { desc = "Close tmux shell" })
  map.set("n", "<leader>vb", ":VimuxInterruptRunner<cr>", { desc = "Interrupt command running in tmux shell" })
  vim.g.VimuxHeight = "30"
  vim.g.VimuxCloseOnExit = 1
end

-- Git fugitive for me
map.del("n", "<leader>gg")
map.del("n", "<leader>gG")
map.set("n", "<leader>gg", ":Git<cr>", { desc = "fugitive" })
map.set("n", "<leader>gl", ":Git log<cr>", { desc = "view logs" })
map.set("n", "<leader>ga", ":Git add %:p<cr>", { desc = "add current file" })
map.set("n", "<leader>gp", ":Git push origin HEAD<cr>", { desc = "push orgin HEAD" })

-- I prefer these keymaps for Lazy and Mason and LSP interactions
map.del("n", "<leader>l")
-- map.del("n", "<leader>cl")
map.set("n", "<leader>lg", ":LspLog<cr>", { desc = "Open LSP logs" })
map.set("n", "<leader>li", ":LspInfo<cr>", { desc = "Open LspInfo interface" })
map.set("n", "<leader>ll", ":Lazy<cr>", { desc = "Open Lazy management interface" })
map.set("n", "<leader>lm", ":Mason<cr>", { desc = "Open Mason management interface" })
map.set("n", "<leader>ln", "<cmd>NullLsInfo<CR>", { desc = "NullLS Information" })
map.set("n", "<leader>lr", ":LspRestart<cr>", { desc = "Restart LSP" })

-- Copilot
local copilot_on = false -- I start with Copilot OFF
vim.api.nvim_create_user_command("CopilotToggle", function()
  if copilot_on then
    vim.cmd("Copilot disable")
    print("Copilot OFF")
  else
    vim.cmd("Copilot enable")
    print("Copilot ON")
  end
  copilot_on = not copilot_on
end, { nargs = 0 })
map.set("", "<leader>ug", ":CopilotToggle<CR>", { noremap = true, silent = true })

-- MarkdownPreview
map.set("n", "<leader>mp", ":MarkdownPreviewToggle<cr>", { desc = "Toggle Markdown preview" })

-- Tab to move to between buffers
if Util.has("bufferline.nvim") then
  map.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
  map.set("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
else
  map.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
  map.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
end

-- Make U the redo command
map.set("n", "U", "<C-r>")

-- I am too old to re-learn how to yank and paste a whole line in vim
vim.cmd([[noremap Y Y]])

-- Allow me to typo q and w
vim.cmd([[
cnoreabbrev <expr> W ((getcmdtype() is# ':' && getcmdline() is# 'W')?('w'):('W'))
cnoreabbrev <expr> Q ((getcmdtype() is# ':' && getcmdline() is# 'Q')?('q'):('Q'))
cnoreabbrev <expr> WQ ((getcmdtype() is# ':' && getcmdline() is# 'WQ')?('wq'):('WQ'))
cnoreabbrev <expr> Wq ((getcmdtype() is# ':' && getcmdline() is# 'Wq')?('wq'):('Wq'))
]])
