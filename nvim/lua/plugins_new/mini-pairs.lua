-- nvim-mini/mini.pairs — auto-pairing for brackets, quotes, etc.
--
-- Sources:
--   - .snapshot/opts.lua [mini.pairs]      — modes, skip_next, skip_ts,
--       skip_unbalanced, markdown
--   - LazyVim plugins/coding.lua at HEAD   — pairs() config helper
--   - LazyVim util/mini.lua at HEAD        — M.pairs() body (inlined)
--
-- The LazyVim M.pairs() helper:
--   1. Registers a Snacks toggle for <leader>up (minipairs_disable)
--   2. Patches pairs.open to handle markdown triple-backtick, skip_next,
--      skip_ts, and skip_unbalanced logic
-- Both are inlined here without the LazyVim util layer.

return {
  src = "https://github.com/nvim-mini/mini.pairs",
  policy = { mode = "commit" },
  config = function()
    local opts = {
      modes = { insert = true, command = true, terminal = false },
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      skip_ts = { "string" },
      skip_unbalanced = true,
      markdown = true,
    }

    -- <leader>up toggle (via Snacks.toggle, mirrors LazyVim M.pairs behavior)
    Snacks.toggle({
      name = "Mini Pairs",
      get = function()
        return not vim.g.minipairs_disable
      end,
      set = function(state)
        vim.g.minipairs_disable = not state
      end,
    }):map("<leader>up")

    local pairs = require("mini.pairs")
    pairs.setup(opts)

    -- Patch pairs.open to handle markdown code-fences, skip_next, skip_ts,
    -- and skip_unbalanced (inlined from LazyVim util/mini.lua M.pairs)
    local open = pairs.open
    pairs.open = function(pair, neigh_pattern)
      if vim.fn.getcmdline() ~= "" then
        return open(pair, neigh_pattern)
      end
      local o, c = pair:sub(1, 1), pair:sub(2, 2)
      local line = vim.api.nvim_get_current_line()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local next = line:sub(cursor[2] + 1, cursor[2] + 1)
      local before = line:sub(1, cursor[2])
      if opts.markdown and o == "`" and vim.bo.filetype == "markdown" and before:match("^%s*``") then
        return "`\n```" .. vim.api.nvim_replace_termcodes("<up>", true, true, true)
      end
      if opts.skip_next and next ~= "" and next:match(opts.skip_next) then
        return o
      end
      if opts.skip_ts and #opts.skip_ts > 0 then
        local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
        for _, capture in ipairs(ok and captures or {}) do
          if vim.tbl_contains(opts.skip_ts, capture.capture) then
            return o
          end
        end
      end
      if opts.skip_unbalanced and next == c and c ~= o then
        local _, count_open = line:gsub(vim.pesc(pair:sub(1, 1)), "")
        local _, count_close = line:gsub(vim.pesc(pair:sub(2, 2)), "")
        if count_close > count_open then
          return o
        end
      end
      return open(pair, neigh_pattern)
    end
  end,
}
