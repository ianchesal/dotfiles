-- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-surround.md
return {
  'echasnovski/mini.surround',
  version = false,
  lazy = false,
  config = function()
    require('mini.surround').setup()
  end
}
