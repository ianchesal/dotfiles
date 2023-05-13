-- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-tabline.md
return {
  'echasnovski/mini.tabline',
  version = false,
  lazy = false,
  config = function()
    require('mini.tabline').setup()
  end
}
