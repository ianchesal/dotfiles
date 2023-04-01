local set = vim.opt
local cmd = vim.cmd
local o = vim.o
local map = vim.api.nvim_set_keymap

-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require('plugins')
require('gitsigns').setup()

require('lualine').setup({
  options = {
    theme = 'nord',
  }
})

require('nvim-tree').setup ({
  view = {
    width = 40,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  }
})

require('telescope').setup({
  extensions = {
    project = {
      base_dirs = {
	      -- {'~/src', max_depth = 4},
        {'~/.config', max_depth = 2},
      },
      hidden_files = true
    }
  }
})

require'nvim-treesitter.configs'.setup({
  ensure_installed = { "lua", "vim", "vimdoc", "query", "ruby", "python", "terraform", "yaml", "json", "bash", "markdown" },
  sync_install = false,
  autoinstall = true,
  highlight = {
    enable = true,
    custom_captures = {
      -- Highlight the @foo.bar capture group with the "Identifier" highlight group.
      ["foo.bar"] = "Identifier",
    },
    disable = {"c"},
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
})


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

-- Telescope bindings
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.command_history, {})
vim.keymap.set('n', '<leader>fm', builtin.marks, {})

-- Fugitive bindings
map( 'n', '<leader>gg', ':Git<cr>', options)

-- Some basic options
set.clipboard = 'unnamedplus'
set.tabstop = 2
set.shiftwidth = 2
set.softtabstop = 2
set.expandtab = true
set.number = true
set.modeline = false

-- Nord looks better without these for whatever reason...
-- set.termguicolors = true
-- o.termguicolors = true

-- Colorschemes
cmd[[colorscheme nord]]
