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
        -- nls.builtins.formatting.fish_indent,
        -- nls.builtins.diagnostics.fish,
        nls.builtins.formatting.stylua,
        nls.builtins.formatting.shfmt,
        -- webdev stuff
        nls.builtins.formatting.deno_fmt,
        nls.builtins.formatting.prettier.with({ filetypes = { "html", "markdown", "css" } }),
        -- Lua
        -- nls.builtins.formatting.stylua,
        -- cpp
        -- nls.builtins.formatting.clang_format,
        -- Terraform
        nls.builtins.formatting.terraform_fmt,
        nls.builtins.diagnostics.terraform_validate,
        -- Ruby w/Rubocop
        -- nls.builtins.formatting.rubocop,
        -- nls.builtins.formatting.rubyfmt,
        -- lint.rubocop,
        -- YAML
        -- nls.builtins.formatting.yq,
        -- Bash, zsh
        -- nls.builtins.formatting.shfmt,
        -- nls.builtins.diagnostics.shellcheck,
        -- Packer
        nls.builtins.formatting.packer,
        -- I dun spel gud
        nls.builtins.hover.dictionary,
        -- nls.builtins.diagnostics.flake8,
      },
    }
  end,
}
