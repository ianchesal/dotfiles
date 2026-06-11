return {
  src = "https://github.com/iamcco/markdown-preview.nvim",
  policy = { mode = "commit" },
  config = function()
    -- vim.pack has no build hooks; mkdp_auto_install triggers the
    -- node-based install on first :MarkdownPreview invocation.
    vim.g.mkdp_auto_install = 1

    -- Buffer-local mapping for markdown files only (the old lazy.nvim
    -- keys spec used `ft = "markdown"` for the same effect).
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("markdown_preview_keys", { clear = true }),
      pattern = "markdown",
      callback = function(ev)
        vim.keymap.set("n", "<leader>cp", "<cmd>MarkdownPreviewToggle<cr>", {
          buffer = ev.buf,
          desc = "Markdown Preview",
        })
      end,
    })
  end,
}
