return {
  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "git_rebase",
        "gitcommit",
        "gitignore",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "ruby",
        "terraform",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
      endwise = { enable = true },
      indent = {
        enable = true,
        disable = { "ruby" },
      },
    },
  },
}
