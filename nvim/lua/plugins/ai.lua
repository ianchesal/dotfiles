return {
  {
    "folke/sidekick.nvim",
    opts = {
      cli = {
        mux = {
          enabled = true,
          create = "split",
          split = {
            size = 0.3,
          },
        },
      },
    },
  },
}
