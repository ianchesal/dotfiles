return {
  {
    "folke/snacks.nvim",
    opts = {
      scroll = {
        -- Disable the smooth scrolling effect
        enabled = false,
      },
      picker = {
        hidden = true,
        -- ignored = true, -- for .gitignore file
      },
      dashboard = {
        preset = {
          -- See: https://patorjk.com/software/taag/#p=display&v=0&f=ANSI%20Shadow&t=IRC
          header = [[
██╗██████╗  ██████╗
██║██╔══██╗██╔════╝
██║██████╔╝██║     
██║██╔══██╗██║     
██║██║  ██║╚██████╗
╚═╝╚═╝  ╚═╝ ╚═════╝
        ]],
        },
      },
    },
  },
}
