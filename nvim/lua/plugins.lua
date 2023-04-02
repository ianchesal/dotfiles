local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'arcticicestudio/nord-vim'
  use 'tpope/vim-fugitive'
  use 'tpope/vim-surround'

  use {
    'nvim-telescope/telescope.nvim',
    requires = 'nvim-lua/plenary.nvim',
    config = function()
      require('config.telescope').setup()
    end,
  }

  use {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup {
        ensure_installed = "all",
        highlight = {
          enable = true,
        },
        additional_vim_regex_highlighting = false,
        autoinstall = true,
        highlight = { enable = true },
        endwise = { enable = true },
        indent = { enable = true },
      }

      -- local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      -- parser_config.just = {
      --   install_info = {
      --     url = "https://github.com/IndianBoy42/tree-sitter-just", -- local path or git repo
      --     files = { "src/parser.c", "src/scanner.cc" },
      --     branch = "main",
      --   },
      --   maintainers = { "@IndianBoy42" },
      -- }
    end,
  }

  use {
    'windwp/nvim-autopairs',
    requires = 'nvim-treesitter',
    -- module = { 'nvim-autopairs.completion.cmp', 'nvim-autopairs' },
    config = function()
      require('config.autopairs').setup()
    end,
  }

  use {
    'RRethy/nvim-treesitter-endwise',
    requires = 'nvim-treesitter',
    event = 'InsertEnter',
    disable = false,
  }

  use {
    "nathom/filetype.nvim",
    config = function()
      require("filetype").setup {
        overrides = {
          extensions = {
            tf = "terraform",
            tfvars = "terraform",
            tfstate = "json",
          }
        }
      }
    end,
  }

  use {
	  'nvim-tree/nvim-tree.lua',
	  requires = 'nvim-tree/nvim-web-devicons',
    config = function()
      require("config.nvimtree").setup()
    end,
  }

  use {
    'lewis6991/gitsigns.nvim',
    requires = {'nvim-lua/plenary.nvim'},
    config = function()
      require("config.gitsigns").setup()
    end,
  }

  use {
    'nvim-lualine/lualine.nvim',
    after = 'nvim-treesitter',
    requires = { 'nvim-tree/nvim-web-devicons', opt = true },
    config = function()
      require("config.lualine").setup()
    end,
  }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
