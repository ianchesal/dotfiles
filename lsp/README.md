# dotfiles/lsp

Installs the language servers and tooling backing the editor configs. Pulls cargo packages (`stylua`, `tree-sitter-cli`), npm packages (`neovim`, `prettier`), and gem-based servers via `bundle install`. There is no config file here, only install logic.

## Tasks

- `rake lsp` — Install LSP servers
