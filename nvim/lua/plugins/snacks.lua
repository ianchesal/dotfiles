return {
  {
    "folke/snacks.nvim",
    opts = {
      scroll = {
        -- Disable the smooth scrolling effect
        enabled = false,
      },
      dashboard = {
        sections = {
          {
            section = "header",
            padding = 2,
          },
          {
            section = "keys",
            padding = 2,
          },
          {
            section = "terminal",
            icon = " ",
            title = "Git Status",
            enabled = vim.fn.isdirectory(".git") == 1,
            cmd = "git diff --stat -B -M -C",
            height = 5,
            indent = 2,
            ttl = 5,
          },
          {
            section = "startup",
          },
        },
      },
    },
  },
}
