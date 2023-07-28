return {
  -- Set lualine as statusline
  'nvim-lualine/lualine.nvim',
  -- See `:help lualine.txt`
  opts = {
    options = {
      icons_enabled = false,
      -- theme = 'onedark', -- auto for theme works pretty well
      -- theme = 'tokyonight',
      component_separators = '|',
      section_separators = '',
    },
  },
}
