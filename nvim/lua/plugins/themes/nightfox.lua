return {
  'EdenEast/nightfox.nvim',   -- https://github.com/EdenEast/nightfox.nvim
  lazy = false,
  config = function()
    require('nightfox').setup({
      options = {
        transparent = false,
      },
    })
    -- Pick one of: nightfox, dayfox, dawnfox, duskfox, nordfox, terafox, carbonfox
  end
}
