return {
  'projekt0n/github-nvim-theme',   -- https://github.com/projekt0n/github-nvim-theme
  lazy = false,
  priority = 1000,
  config = function()
    require('github-theme').setup({
      options = {
        styles = {
          comments = 'NONE',
          keywords = 'NONE',
        },
      }
    })
  end
}
