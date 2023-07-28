return {
  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "javascript",
        "json",
        "jsonc",
        "lua",
        "markdown",
        "markdown_inline",
        "regex",
        "ruby",
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
