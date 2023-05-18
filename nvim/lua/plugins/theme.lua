return {
  -- 'folke/tokyonight.nvim',
  -- config = function()
  --   require('tokyonight').setup({
  --     style = 'night',
  --     transparent = false,
  --     styles = {
  --       -- Fuck italics in the terminal. Who wants that shit?
  --       comments = { italic = false },
  --       keywords = { italic = false },
  --       functions = { italic = false },
  --       variables = { italic = false },
  --     },
  --   })
  --   vim.cmd.colorscheme 'tokyonight'
  -- end
  'navarasu/onedark.nvim',
  config = function()
    require('onedark').setup({
      style = 'darker',      -- Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
      lualine = {
        transparent = false, -- lualine center bar transparency
      },
    })
    vim.cmd.colorscheme 'onedark'
  end
}
