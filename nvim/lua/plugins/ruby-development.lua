-- The LazyVim ruby development plugin thingy was defaulting to Solargraph
-- So this copies what I need from that config but omits the Solargraph stuff
-- because Ruby LSP is what we're using now.
-- It copies stuff from here: https://www.lazyvim.org/extras/lang/ruby
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "ruby",
      })
    end,
  },
  -- {
  --   "suketa/nvim-dap-ruby",
  --   config = function()
  --     require("dap-ruby").setup()
  --   end,
  -- },
  -- {
  --   "olimorris/neotest-rspec",
  -- },
  -- {
  --   "mfussenegger/nvim-dap",
  --   optional = true,
  --   dependencies = {
  --     "suketa/nvim-dap-ruby",
  --     config = function()
  --       require("dap-ruby").setup()
  --     end,
  --   },
  -- },
  -- {
  --   -- https://github.com/rgroli/other.nvim
  --   "rgroli/other.nvim",
  --   lazy = false,
  --   config = function()
  --     require("other-nvim").setup({
  --       mappings = {
  --         "livewire",
  --         "angular",
  --         "laravel",
  --         "rails",
  --         "golang",
  --       },
  --     })
  --   end,
  -- },
}
