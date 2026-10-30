-- Ctrl-h/j/k/l across nvim splits and multiplexer panes. Under tmux this is
-- plain vim-tmux-navigator. Under herdr ($HERDR_PANE_ID set) nvim moves between
-- its own splits and, when the window doesn't change (an edge), hands off to
-- ~/.config/herdr/nav.sh, the herdr half, which moves (and wraps) herdr focus.
local function navigate(wincmd, direction, tmux_cmd)
  return function()
    if vim.env.HERDR_PANE_ID == nil then
      vim.cmd(tmux_cmd)
      return
    end
    local win = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(wincmd)
    if vim.api.nvim_get_current_win() == win then
      -- --no-passthrough: nav.sh would otherwise see nvim in this pane and send
      -- the key straight back. nav.sh wraps at herdr's own edges, as tmux does.
      local nav = vim.fn.expand("~/.config/herdr/nav.sh")
      if vim.fn.executable(nav) == 1 then
        vim.system({ nav, "--no-passthrough", direction })
        return
      end
      -- No nav.sh (not applied yet): plain move, no wrap. --current, not
      -- $HERDR_PANE_ID: herdr renumbers pane ids when a pane closes, and the
      -- focused pane is always ours while we handle the key.
      -- $HERDR_BIN_PATH is a Cellar path a brew upgrade can delete.
      local herdr = vim.env.HERDR_BIN_PATH
      if herdr == nil or vim.fn.executable(herdr) == 0 then
        herdr = "herdr"
      end
      vim.system({ herdr, "pane", "focus", "--current", "--direction", direction })
    end
  end
end

return {
  src = "https://github.com/christoomey/vim-tmux-navigator",
  policy = { mode = "commit" },
  config = function()
    -- The plugin's plugin/ script is sourced after config() and would replace
    -- the maps below with its own tmux-only ones.
    vim.g.tmux_navigator_no_mappings = 1
    vim.keymap.set("n", "<c-h>", navigate("h", "left", "TmuxNavigateLeft"))
    vim.keymap.set("n", "<c-j>", navigate("j", "down", "TmuxNavigateDown"))
    vim.keymap.set("n", "<c-k>", navigate("k", "up", "TmuxNavigateUp"))
    vim.keymap.set("n", "<c-l>", navigate("l", "right", "TmuxNavigateRight"))
  end,
}
