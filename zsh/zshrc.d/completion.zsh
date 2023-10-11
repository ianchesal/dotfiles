# From: https://superuser.com/a/815317
# This is *exactly* the type of completion I like. Fuzzy enough but not too smaht.
#
# 0 -- vanilla completion (abc => abc)
# 1 -- smart case completion (abc => Abc)
# 2 -- word flex completion (abc => A-big-Car)
# 3 -- full flex completion (abc => ABraCadabra)
zstyle ':completion:*' matcher-list '' \
  'm:{a-z\-}={A-Z\_}' \
  'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' \
  'r:|?=** m:{a-z\-}={A-Z\_}'

# Don't complete users. It's annoying.
# See: https://unix.stackexchange.com/questions/57408/why-is-zsh-oh-my-zsh-completing-directories-that-dont-exist
zstyle ':completion:*' users asgeo1 root ianchesal

# Recommended for use with fzf-tab
# See: https://github.com/Aloxaf/fzf-tab#configure
# disable sort when completing `git checkout`
# zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
