-- Ruby (and Lua/bash/...) auto-`end` insertion.
-- COMPAT GATE (Task 11): verify against treesitter main; may need replacement.
-- At the locked rev its plugin/ file self-initializes on nvim >= 0.9 via its
-- own FileType autocmd (require("nvim-treesitter-endwise").init()) and does
-- not use the master-branch module system, so no config() is needed -- it
-- just has to be on the runtimepath.
return {
  src = "https://github.com/RRethy/nvim-treesitter-endwise",
  policy = { mode = "commit" },
  priority = 22,
}
