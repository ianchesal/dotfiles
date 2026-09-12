# See: https://sw.kovidgoyal.net/kitty/shell-integration/#manual-shell-integration
if test -n "$KITTY_INSTALLATION_DIR"; then
    export KITTY_SHELL_INTEGRATION="enabled"
    autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
    kitty-integration
    unfunction kitty-integration
fi

if [[ "$TERM" == 'xterm-kitty' ]]; then
    alias kssh='kitty +kitten ssh'
    compdef kssh='ssh'
fi
