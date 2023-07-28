return {
  'catppuccin/nvim', -- https://github.com/catppuccin/catppuccin
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require('github-theme').setup({
      flavour = "mocha", -- latte, frappe, macchiato, mocha,
      term_colors = true,
      dim_inactive = {
        enabled = true,    -- dims the background color of inactive window
        shade = "dark",
        percentage = 0.15, -- percentage of the shade to apply to the inactive window
      },
      no_italic = true,    -- Force no italic
      options = {
        styles = {
          comments = 'NONE',
          keywords = 'NONE',
        },
      }
    })
  end
}
