# History: large, deduped, shared across concurrent sessions.
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
HISTTIMEFORMAT='%F %T  '
shopt -s histappend

# Append this session's new lines, clear this shell's history buffer,
# then re-read the file -- so a command typed in one terminal shows up
# in another's history immediately, the closest bash gets to zsh's
# SHARE_HISTORY.
bash_history_sync() {
  history -a
  history -c
  history -r
}
PROMPT_COMMAND="bash_history_sync${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
