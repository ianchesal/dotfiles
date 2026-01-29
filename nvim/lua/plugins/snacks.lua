return {
  {
    "folke/snacks.nvim",
    opts = {
      scroll = {
        -- Disable the smooth scrolling effect
        enabled = false,
      },
      picker = {
        sources = {
          files = {
            hidden = true, -- Show hidden/dotfiles
            ignored = false, -- Respect .gitignore
          },
          grep = {
            hidden = true, -- Also search in hidden files
            ignored = false,
          },
        },
      },
      explorer = {
        enabled = false,
      },
      indent = {
        enabled = false,
      },
      dashboard = {
        enabled = true,
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
