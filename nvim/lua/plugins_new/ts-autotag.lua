-- Automatically add/rename closing tags for HTML and JSX.
-- Standalone setup(); does not depend on the treesitter module system.
return {
  src = "https://github.com/windwp/nvim-ts-autotag",
  policy = { mode = "commit" },
  config = function()
    require("nvim-ts-autotag").setup({})
  end,
}
