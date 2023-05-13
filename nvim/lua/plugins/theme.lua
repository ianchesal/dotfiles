-- {
--   -- Theme inspired by Atom
--   'navarasu/onedark.nvim',
--   priority = 1000,
--   config = function()
--     vim.cmd.colorscheme 'onedark'
--   end,
-- },

return {
  'folke/tokyonight.nvim',
  config = function()
    require('tokyonight').setup({
      style = 'night',
      transparent = false,
      styles = {
        -- Fuck italics in the terminal. Who wants that shit?
        comments = { italic = false },
        keywords = { italic = false },
        functions = { italic = false },
        variables = { italic = false },
      },
    })
    vim.cmd.colorscheme 'tokyonight'
  end
}
