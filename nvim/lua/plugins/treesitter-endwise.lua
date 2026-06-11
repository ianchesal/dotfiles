-- Ruby (and Lua/bash/...) auto-`end` insertion.
-- COMPAT (Task 11, verified): at the locked rev its plugin/ file
-- self-initializes on nvim >= 0.9 via its own FileType autocmd
-- (require("nvim-treesitter-endwise").init()) and uses only core
-- vim.treesitter APIs -- no master-branch module system involved.
--
-- One tweak is required on nvim 0.12: endwise() reads the parser's existing
-- tree without ever calling parser:parse(), and 0.12's highlighter parses
-- asynchronously, so at <CR>-time the tree is stale and the endwise query
-- matches nothing. The plugin fires `User PreNvimTreesitterEndwiseCR` right
-- before running (only for buffers it tracks), so force a synchronous parse
-- there. parse(true) includes injected languages (e.g. ruby fences in
-- markdown), which is_supported() explicitly handles.
return {
  src = "https://github.com/RRethy/nvim-treesitter-endwise",
  policy = { mode = "commit" },
  priority = 22,
  config = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "PreNvimTreesitterEndwiseCR",
      group = vim.api.nvim_create_augroup("user_endwise_sync_parse", { clear = true }),
      callback = function()
        local ok, parser = pcall(vim.treesitter.get_parser)
        if ok and parser then
          parser:parse(true)
        end
      end,
    })
  end,
}
