-- nvim-mini/mini.surround — surround actions with gs-prefix mappings.
--
-- Sources:
--   - .snapshot/opts.lua [mini.surround]          — mappings table
--   - .snapshot/keys.lua [mini.surround]          — 7 keymaps (gsa–gsn)
--   - LazyVim extras/coding/mini-surround.lua     — opts structure

return {
  src = "nvim-mini/mini.surround",
  policy = { mode = "commit" },
  config = function()
    require("mini.surround").setup({
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
    })
  end,
}
