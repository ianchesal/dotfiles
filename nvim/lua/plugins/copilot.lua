return {
  "zbirenbaum/copilot.lua",
  event = "InsertEnter",
  lazy = false,
  opts = {
    enabled = true,
    suggestion = {
      enable = false,
    },
    panel = {
      enable = false,
    },
    filetypes = {
      yaml = false,
      markdown = false,
      help = false,
      gitcommit = false,
      gitrebase = false,
      ["."] = false,
    },
  }
}
