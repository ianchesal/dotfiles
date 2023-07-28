return {
  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "ruby",
        "terraform",
        "terraform",
        "tsx",
        "vim",
        "yaml",
        "git_rebase",
        "gitcommit",
        "gitignore",
      },
    },
  },
}
