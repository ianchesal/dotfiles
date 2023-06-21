return {
  'folke/flash.nvim',
  event = 'VeryLazy',
  opts = {},
  keys = {
    {
      's',
      mode = { 'n', 'x', 'o' },
      function()
        -- default options: exact mode, multi window, all directions, with a backdrop
        require('flash').jump()
      end,
    },
    {
      'S',
      mode = { 'o', 'x' },
      function()
        require('flash').treesitter()
      end,
    },
  },
}
