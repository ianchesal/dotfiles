# autoquote metacharacters in urls
autoload -U url-quote-magic
zle -N self-insert url-quote-magic
# make sure to escape * in scp commands
zstyle -e :urlglobber url-other-schema '[[ $words[1] == scp ]] && reply=("*") || reply=(http https ftp)'
