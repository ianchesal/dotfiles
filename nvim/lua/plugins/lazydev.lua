-- lua_ls niceties for editing this Neovim config.
-- Library list from the LazyVim snapshot, with the lazy.nvim/LazyVim entries
-- stripped (those plugins are gone after the vim.pack migration).
return {
  src = "https://github.com/folke/lazydev.nvim",
  policy = { mode = "commit" },
  config = function()
    require("lazydev").setup({
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "nvim-lspconfig", words = { "lspconfig.settings" } },
      },
    })
  end,
}
