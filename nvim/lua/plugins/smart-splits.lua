return {
  "mrjones2014/smart-splits.nvim",
  config = function()
    local ss = require("smart-splits")
    local keymap = vim.keymap

    -- recommended mappings
    -- resizing splits
    -- these keymaps will also accept a range,
    -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
    keymap.set("n", "<A-h>", ss.resize_left)
    keymap.set("n", "<A-j>", ss.resize_down)
    keymap.set("n", "<A-k>", ss.resize_up)
    keymap.set("n", "<A-l>", ss.resize_right)
    -- moving between splits
    keymap.set("n", "<C-h>", ss.move_cursor_left)
    keymap.set("n", "<C-j>", ss.move_cursor_down)
    keymap.set("n", "<C-k>", ss.move_cursor_up)
    keymap.set("n", "<C-l>", ss.move_cursor_right)
    keymap.set("n", "<C-\\>", ss.move_cursor_previous)
    -- swapping buffers between windows
    -- keymap.set("n", "<leader><leader>h", ss.swap_buf_left)
    -- keymap.set("n", "<leader><leader>j", ss.swap_buf_down)
    -- keymap.set("n", "<leader><leader>k", ss.swap_buf_up)
    -- keymap.set("n", "<leader><leader>l", ss.swap_buf_right)
  end,
}
