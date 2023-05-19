return {
  -- 'folke/tokyonight.nvim',
  -- lazy = false,
  -- priority = 1000,
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
  -- 'navarasu/onedark.nvim',
  -- lazy = false,
  -- priority = 1000,
  -- config = function()
  --   require('onedark').setup({
  --     style = 'darker',      -- Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
  --     lualine = {
  --       transparent = false, -- lualine center bar transparency
  --     },
  --   })
  --   vim.cmd.colorscheme 'onedark'
  -- end
  'projekt0n/github-nvim-theme', -- https://github.com/projekt0n/github-nvim-theme
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

    vim.cmd('colorscheme github_dark_dimmed')
  end,
}
