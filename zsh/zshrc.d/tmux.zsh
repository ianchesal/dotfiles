# Keep TMUX_SESSION current before each prompt so oh-my-posh can display it.
if [[ -n "$TMUX" ]]; then
  function _update_tmux_session() {
    TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null)
    export TMUX_SESSION
  }
  add-zsh-hook precmd _update_tmux_session
  _update_tmux_session
fi
