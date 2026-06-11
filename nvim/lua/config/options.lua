-- Options. Loaded first by init.lua, before any plugin.

-- Leader keys must be set before keymaps and plugins are configured.
-- (LazyVim used to do this; nothing else will now.)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Some OS detectors
local is_wsl = vim.fn.has("wsl") == 1

local opt = vim.opt
local g = vim.g

-- ─────────────────────────────────────────────────────────────────────────
-- LazyVim-derived defaults
-- Transcribed from LazyVim lua/lazyvim/config/options.lua at the locked rev,
-- cross-checked against .snapshot/options.lua (the resolved live state).
--
-- Deliberately NOT carried forward:
--   * lazyvim_picker / lazyvim_cmp / ai_cmp / root_spec / root_lsp_ignore /
--     deprecation_warnings / trouble_lualine — LazyVim-internal wiring.
--   * vim.g.snacks_animate — snacks defaults it to true; set it to false
--     here if you ever want to kill all animations globally.
--   * opt.formatexpr — LazyVim pointed it at its format util. gq falls back
--     to the default; <leader>cf (conform.lua) is the formatting entry point.
--   * opt.statusline — the snapshot's "%#lualine_transparent#" is set by
--     lualine itself at runtime.
-- ─────────────────────────────────────────────────────────────────────────

-- conform.lua's format-on-save gate reads this (with vim.b.autoformat as the
-- buffer-local override; see the markdown autocmd).
g.autoformat = true

opt.autowrite = true -- Enable auto write
-- Only set clipboard if not in ssh, so the OSC 52 integration works.
opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs
opt.fillchars = {
  foldopen = "\u{F47C}", -- nf-oct-chevron_down
  foldclose = "\u{F460}", -- nf-oct-chevron_right
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
-- Folds stay vim-default (indent), persisted across sessions by the
-- mkview/loadview autocmds. LazyVim's locked rev DID wire a
-- treesitter/LSP foldexpr via set_default(), but it never activated on
-- this setup (the snapshot resolved to foldmethod=indent), so that wiring
-- is deliberately not ported.
opt.foldlevel = 99
opt.foldmethod = "indent"
opt.foldtext = ""
opt.formatoptions = "jcroqlnt" -- tcqj
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.ignorecase = true -- Ignore case
opt.inccommand = "nosplit" -- preview incremental substitute
opt.jumpoptions = "view"
opt.laststatus = 3 -- global statusline
opt.linebreak = true -- Wrap lines at convenient points
opt.list = true -- Show some invisible characters (tabs...
opt.mouse = "a" -- Enable mouse mode
opt.number = true -- Print line number
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.relativenumber = true -- Relative line numbers (deliberately kept: LazyVim default)
opt.ruler = false -- Disable the default ruler
opt.scrolloff = 4 -- Lines of context
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shiftround = true -- Round indent
opt.shiftwidth = 2 -- Size of an indent
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.showmode = false -- Dont show mode since we have a statusline
opt.sidescrolloff = 8 -- Columns of context
opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
opt.smartcase = true -- Don't ignore case with capitals
opt.smartindent = true -- Insert indents automatically
opt.smoothscroll = true
opt.spelllang = { "en" }
opt.splitbelow = true -- Put new windows below current
opt.splitkeep = "screen"
opt.splitright = true -- Put new windows right of current
-- LazyVim used its own statuscolumn util; snacks provides the equivalent.
-- The snacks statuscolumn module's auto-setup is disabled in plugins/snacks.lua
-- and the option is owned here instead. Evaluated lazily at redraw time, by
-- which point snacks is loaded.
opt.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]
opt.tabstop = 2 -- Number of spaces tabs count for
opt.termguicolors = true -- True color support
opt.timeoutlen = 300 -- Lower than default (1000) to quickly trigger which-key
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200 -- Save swap file and trigger CursorHold
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width
opt.wrap = false -- Disable line wrap

-- Fix markdown indentation settings
g.markdown_recommended_style = 0

-- ─────────────────────────────────────────────────────────────────────────
-- User options (carried over verbatim from the pre-swap config)
-- ─────────────────────────────────────────────────────────────────────────

opt.autoread = true
opt.breakindent = true
opt.visualbell = true

-- WSL Clipboard support
if is_wsl then
  -- This is NeoVim's recommended way to solve clipboard sharing if you use WSL
  -- See: https://github.com/neovim/neovim/wiki/FAQ#how-to-use-the-windows-clipboard-from-wsl
  g.clipboard = {
    name = "wsl-clip",
    copy = {
      ["+"] = "clip.exe",
      ["*"] = "clip.exe",
    },
    paste = {
      ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
end

-- Save buffers when navigating to a tmux pane
g.tmux_navigator_save_on_switch = 2

-- Don't care about these
g.loaded_perl_provider = 0
g.loaded_python3_provider = 0
