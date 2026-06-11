return {
  src = "https://github.com/shellRaining/hlchunk.nvim",
  policy = { mode = "commit" },
  config = function()
    require("hlchunk").setup({
      chunk = {
        enable = true,
        chars = { right_arrow = "─" },
        style = "#75A1FF",
        duration = 50,
        delay = 10,
      },
      indent = { enable = true },
      line_num = { enable = true },
      exclude_filetypes = { "help", "git", "markdown", "snippets", "text", "gitconfig", "alpha", "dashboard" },
    })
  end,
}
