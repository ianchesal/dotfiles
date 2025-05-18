return {
  "m4xshen/hardtime.nvim",
  lazy = false,
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    max_count = 10, -- default: 3
    enabled = false,
  },
  keys = {
    { "<leader>uH", "<cmd>Hardtime toggle<cr>", desc = "Hardtime" },
  },
}
