# dotfiles/vim

Old-school Vim configuration kept around for machines where Neovim can't be
installed. Not used day-to-day. Uses [vim-plug](https://github.com/junegunn/vim-plug)
for plugin management, which bootstraps itself on first launch.

## Layout

```
vimrc        The configuration; symlinked to ~/.vimrc
vim.rake     Install/update/clean tasks
```

## Tasks

- `rake vim` — install (symlink `vimrc` to `~/.vimrc`, create `~/.vim`)
- `rake vim:update` — update vim-plug plugins (PlugUpgrade, PlugInstall, PlugUpdate)

## Notes

These tasks are not wired into `rake all`/`rake clean`/`rake update` by default
(commented out at the bottom of `vim.rake`); run them explicitly.
