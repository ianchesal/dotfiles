# Vi mode is now handled by jeffreytse/zsh-vi-mode plugin
# All vi mode configuration including:
# - bindkey -v setup
# - edit-command-line loading and keybinding
# - zvm_after_init() hook for restoring fzf and history-search keybindings
# is now in .zshrc before plugins load to ensure proper initialization order
