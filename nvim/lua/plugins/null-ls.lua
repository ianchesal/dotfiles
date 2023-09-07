return {
  "jose-elias-alvarez/null-ls.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "mason.nvim" },
  opts = function()
    local nls = require("null-ls")
    return {
      root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git"),
      sources = {
        -- See: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
        -- nls.builtins.formatting.stylua,
        -- nls.builtins.formatting.shfmt,
        -- webdev stuff
        -- nls.builtins.formatting.deno_fmt,
        -- nls.builtins.formatting.prettier.with({ filetypes = { "html", "markdown", "css" } }),
        -- Terraform
        -- nls.builtins.formatting.terraform_fmt,
        -- nls.builtins.diagnostics.terraform_validate,
        -- Packer
        -- nls.builtins.formatting.packer,
        -- I dun spel gud
        -- nls.builtins.hover.dictionary,
      },
    }
  end,
}
