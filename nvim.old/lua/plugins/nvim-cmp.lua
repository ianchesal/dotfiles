return {
  -- Autocompletion
  'hrsh7th/nvim-cmp',
  dependencies = { 'hrsh7th/cmp-nvim-lsp', 'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip',
    'rafamadriz/friendly-snippets', "zbirenbaum/copilot-cmp" },
  config = function()
    require("copilot_cmp").setup()
  end,
}
