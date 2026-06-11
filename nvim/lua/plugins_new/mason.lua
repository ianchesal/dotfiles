-- mason.nvim: external tool installer (formatters, linters, LSP servers).
--
-- ensure_installed is NOT a mason.nvim option -- LazyVim implemented it with
-- custom code. The trimmed port below installs missing packages through the
-- mason registry after setup() (LazyVim's FileType-retrigger on install
-- success was lazy.nvim machinery and is dropped).
--
-- Package list: union of the old user mason.lua and the LazyVim snapshot
-- resolution, minus js-debug-adapter (DAP cluster dropped), plus
-- tree-sitter-cli (required by treesitter `main` to build parsers; LazyVim
-- auto-installed it via mason too).
local ensure_installed = {
  "bash-language-server",
  "deno",
  "diagnostic-languageserver",
  "dockerfile-language-server",
  "erb-formatter",
  "erb-lint",
  "hadolint",
  "helm-ls",
  "json-lsp",
  "jsonnet-language-server",
  "lua-language-server",
  "prettier",
  "prettierd",
  "rubocop",
  "ruby-lsp",
  "shellcheck",
  "shfmt",
  "sqlls",
  "stylua",
  "terraform-ls",
  "tflint",
  "tree-sitter-cli",
  "typescript-language-server",
  "yaml-language-server",
}

return {
  src = "https://github.com/mason-org/mason.nvim",
  policy = { mode = "commit" },
  priority = 30,
  config = function()
    require("mason").setup({})

    local mr = require("mason-registry")
    mr.refresh(function()
      for _, tool in ipairs(ensure_installed) do
        local ok, p = pcall(mr.get_package, tool)
        if ok and not p:is_installed() then
          p:install()
        end
      end
    end)

    -- The Mason UI still exists in this setup; keep LazyVim's keymap.
    vim.keymap.set("n", "<leader>cm", "<cmd>Mason<cr>", { desc = "Mason" })
  end,
}
