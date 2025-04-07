return {
  "preservim/vimux",
  enabled = function(_, _)
    -- This only works if we're inside a tmux session
    local tmux_env = os.getenv("TMUX")
    return tmux_env ~= nil and tmux_env ~= ""
  end,
}
