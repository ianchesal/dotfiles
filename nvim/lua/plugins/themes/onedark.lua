return {
  'navarasu/onedark.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    require('onedark').setup({
      style = 'darker',        -- Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
      lualine = {
        transparent = false,   -- lualine center bar transparency
      },
    })
  end
}
