return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim", -- required
    "sindrets/diffview.nvim", -- optional - Diff integration

    -- Only one of these is needed.
    -- "nvim-telescope/telescope.nvim", -- optional
    "ibhagwan/fzf-lua", -- optional
    -- "echasnovski/mini.pick", -- optional
  },
  opts = {
    kind = "floating",
    disable_commit_confirmation = true,
    graph_style = "unicode", -- "ascii" if this breaks in remote terminals
    initial_branch_name = "ian/",
    commit_editor = {
      show_staged_diff = true,
      staged_diff_split_kind = "split",
    },
    integrations = {
      diffview = true,
      fzf_lua = true,
    },
  },
}
