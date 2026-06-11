-- Context-sensitive indentexpr (e.g. ruby indentation inside markdown
-- fences). COMPAT (Task 11, verified): context_indent() itself uses only
-- core vim.treesitter APIs (get_parser/language_for_range) -- fine on
-- treesitter main.
--
-- We deliberately do NOT call the plugin's setup(): its BufRead hook fires
-- before the nested filetype-detection chain (filetype detection runs inside
-- BufReadPost, after init-registered autocmds), so its wrapper gets
-- clobbered by indent.vim and by our user_treesitter FileType autocmd. Under
-- lazy.nvim this raced the other way (the plugin loaded lazily, after
-- filetypedetect). Instead we install the same wrapper on FileType: this
-- config runs after treesitter's (priority 20 < 50), so our autocmd is
-- registered -- and therefore fires -- after both indent.vim's and
-- user_treesitter's, wrapping the final indentexpr.
return {
  src = "https://github.com/wurli/contextindent.nvim",
  policy = { mode = "commit" },
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_contextindent", { clear = true }),
      callback = function(ev)
        -- Real file buffers only. Crucially this excludes the nofile temp
        -- buffer vim.filetype.get_option() uses: contextindent itself calls
        -- get_option(lang, "indentexpr") to resolve the inner language's
        -- indentexpr, and wrapping inside that temp buffer would poison the
        -- ft option cache with a self-referential (infinitely recursive)
        -- indentexpr. (The plugin's own BufRead hook never had this problem
        -- because BufRead doesn't fire for scratch buffers.)
        if vim.bo[ev.buf].buftype ~= "" then
          return
        end
        local cur = vim.bo[ev.buf].indentexpr
        if cur:find("contextindent", 1, true) then
          return -- already wrapped
        end
        -- same template the plugin's own setup() uses
        vim.bo[ev.buf].indentexpr = ('v:lua.require("contextindent").context_indent("%s")'):format(cur)
      end,
    })
  end,
}
