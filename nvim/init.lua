local set = vim.opt
local cmd = vim.cmd
local o = vim.o
local g = vim.g
local map = vim.api.nvim_set_keymap
local keymap = vim.keymap.set

-- Global stuff
g.python3_host_prog = '~/.pyenv/versions/neovim3/bin/python'
g.markdown_fenced_languages = {
  "bash=sh",
  "python",
  "lua",
  "nushell",
}

require('plugins')

-- Mappings
map( 'n', '<Space>', '', {})
vim.g.mapleader = ' '

options = { noremap = true }

map( 'n', '<C-l>', ':nohlsearch<cr>', options)
map( 'n', '<C-n>', ':NvimTreeToggle<cr>', options)
map( 'n', '<tab>', ':bn<cr>', options)
map( 'n', '<s-tab>', ':bp<cr>', options)
--map( 'n', '<leader>tt', ':TransparentToggle<cr>', options)
-- I am too old to relearn that Y copies from cursor position to the end of the line
-- I need it to copy the entire line into the buffer
cmd[[noremap Y Y]]
-- I should figure out the lua way to do this one
cmd[[noremap ; :]]
-- Paste over currently selected text without yanking it
keymap("v", "p", '"_dP')
-- prevent typo when pressing `wq` or `q`
cmd [[
cnoreabbrev <expr> W ((getcmdtype() is# ':' && getcmdline() is# 'W')?('w'):('W'))
cnoreabbrev <expr> Q ((getcmdtype() is# ':' && getcmdline() is# 'Q')?('q'):('Q'))
cnoreabbrev <expr> WQ ((getcmdtype() is# ':' && getcmdline() is# 'WQ')?('wq'):('WQ'))
cnoreabbrev <expr> Wq ((getcmdtype() is# ':' && getcmdline() is# 'Wq')?('wq'):('Wq'))
]]

-- Telescope bindings
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.command_history, {})
vim.keymap.set('n', '<leader>fm', builtin.marks, {})

-- Fugitive bindings
map( 'n', '<leader>gg', ':Git<cr>', options)

-- Bufdelete bindings
map( 'n', '<leader>bq', ':Bdelete<cr>', options)

-- Some basic options
set.autoread = true
set.background = 'dark'
set.completeopt = {'menuone', 'noinsert', 'noselect'}  -- completion options (for deoplete)
-- set.cursorline = true               -- highlight current line
set.encoding = "utf-8"
set.expandtab = true                -- spaces instead of tabs
set.hidden = true                   -- enable background buffers
set.ignorecase = true               -- ignore case in search
set.joinspaces = false              -- no double spaces with join
-- set.list = true                     -- show some invisible characters
set.mouse = "nv"                    -- Enable mouse in normal and visual modes
set.number = true                   -- show line numbers
-- set.relativenumber = true           -- number relative to current line
set.scrolloff = 4                   -- lines of context
set.shiftround = true               -- round indent
set.shiftwidth = 2                  -- size of indent
set.sidescrolloff = 8               -- columns of context
set.smartcase = true                -- do not ignore case with capitals
set.smartindent = true              -- insert indents automatically
set.splitbelow = true               -- put new windows below current
set.splitright = true               -- put new vertical splits to right
set.wildmode = {'list', 'longest'}  -- command-line completion mode
set.clipboard = 'unnamedplus'       -- share clipboard with OS X and then some
set.modeline = false                -- disable modeline support, it's annoying
set.softtabstop = 2
set.tabstop = 2
set.wrap = false                    -- don't wrap long lines, i have a big...screen

cmd[[filetype plugin on]]
cmd[[autocmd FocusGained * checktime]]

-- Deoplete config
cmd[[let g:deoplete#enable_at_startup = 1]]

-- Colorschemes
cmd[[colorscheme nord]]
