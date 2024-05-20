if true then
  return {}
end

-- None of this working at present. There's some bad interaction
-- between this and LazyVim that ends up breaking snippets entirely
-- if you try and configure this plugin.

return {
  "garymjr/nvim-snippets",
  opts = {
    -- create_cmp_source = true,
    -- friendly_snippets = false, -- LazyVim has this covered another way
    -- search_paths = { vim.fn.stdpath("config") },
  },
}
