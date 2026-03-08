return {
  {
    "folke/sidekick.nvim",
    opts = {
      nes = {
        -- Disables "next edit suggestions" -- I don't like this feature
        enabled = false,
      },
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
