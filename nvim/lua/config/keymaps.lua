-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local util = require("lazyvim.util")
local map = vim.keymap
local my_keymaps = {}

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

  my_keymaps["v"] = {
    name = "vimux",
    p = {
      "<cmd>VimuxPromptCommand<cr>",
      "Run command in tmux shell",
    },
    l = {
      "<cmd>VimuxRunLastCommand<cr>",
      "Run last shell command",
    },
    i = {
      "<cmd>VimuxInspectRunner<cr>",
      "Inspect tmux shell",
    },
    z = {
      "<cmd>VimuxZoomRunner<cr>",
      "Zoom tmux shell",
    },
    k = {
      "<cmd>VimuxCloseRunner<cr>",
      "Close tmux shell",
    },
    b = {
      "<cmd>VimuxInterruptRunner<cr>",
      "Interrupt command running in tmux shell",
    },
  }

  vim.g.VimuxHeight = "30"
  vim.g.VimuxCloseOnExit = 1
end

-- Git fugitive for me
map.del("n", "<leader>gg")
map.del("n", "<leader>gG")
my_keymaps["g"] = {
  name = "git",
  g = {
    "<cmd>Git<cr>",
    "Fugitive",
  },
  l = {
    "<cmd>Git log<cr>",
    "View logs",
  },
  a = {
    "<cmd>Git add %:p<cr>",
    "Add current file",
  },
  p = {
    "<cmd>Git push origin HEAD<cr>",
    "Push: origin --> HEAD",
  },
}

-- I prefer different keymaps for Lazy and Mason and LSP interactions
map.del("n", "<leader>l")
my_keymaps["l"] = {
  -- Mason and LSP
  name = "lsp",
  g = {
    "<cmd>LspLog<cr>",
    "Open LSP logs",
  },
  h = {
    "<cmd>LazyHealth<cr>",
    "Health diagnostics",
  },
  i = {
    "<cmd>LspInfo<cr>",
    "Open LspInfo interface",
  },
  l = {
    "<cmd>Lazy<cr>",
    "Open Lazy management interface",
  },
  m = {
    "<cmd>Mason<cr>",
    "Open Mason management interface",
  },
  -- n = {
  --   "<cmd>NullLsInfo<cr>",
  --   "NullLS Information",
  -- },
  r = {
    "<cmd>LspRestart<cr>",
    "Restart all LSPs",
  },
}

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

-- Telescope
my_keymaps["t"] = {
  name = "telescope",
  k = {
    "<cmd>Telescope keymaps<cr>",
    "Seach keymaps",
  },
  t = {
    name = "terraform",
    t = {
      "<cmd>Telescope terraform_doc<cr>",
      "Search Terraform documents",
    },
    m = {
      "<cmd>Telescope terraform_doc modules<cr>",
      "Search Terraform modules",
    },
    g = {
      "<cmd>Telescope terraform_doc full_name=hashicorp/google<cr>",
      "Search Terraform: google provider",
    },
  },
}

-- Make U the redo command
-- map.set("n", "U", "<C-r>")

-- Tab to move to between buffers
if util.has("bufferline.nvim") then
  map.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
  map.set("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
else
  map.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
  map.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
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

require("which-key").register(my_keymaps, { prefix = "<leader>" })
