-- nvim-mini/mini.ai — extended text objects.
--
-- Sources:
--   - .snapshot/opts.lua [mini.ai]          — n_lines=500, custom_textobjects
--   - LazyVim plugins/coding.lua at HEAD    — textobject definitions
--   - LazyVim util/mini.lua at HEAD         — ai_buffer helper (inlined)
--
-- Custom textobjects ported:
--   o = treesitter block/conditional/loop
--   f = treesitter function
--   c = treesitter class
--   t = HTML/XML tags
--   d = digits
--   e = CamelCase/snake_case word
--   g = entire buffer  (ai_buffer inlined from LazyVim.mini.ai_buffer)
--   u = function call  (with dot in name)
--   U = function call  (without dot in name)
--
-- SKIPPED: which-key ai-textobject descriptions (LazyVim.mini.ai_whichkey
-- requires the LazyVim util layer and which-key integration that we don't
-- carry forward in this bare setup).

return {
  src = "https://github.com/nvim-mini/mini.ai",
  policy = { mode = "commit" },
  config = function()
    local ai = require("mini.ai")

    -- Inlined from LazyVim util/mini.lua M.ai_buffer
    local function ai_buffer(ai_type)
      local start_line, end_line = 1, vim.fn.line("$")
      if ai_type == "i" then
        local first_nonblank = vim.fn.nextnonblank(start_line)
        local last_nonblank = vim.fn.prevnonblank(end_line)
        if first_nonblank == 0 or last_nonblank == 0 then
          return { from = { line = start_line, col = 1 } }
        end
        start_line, end_line = first_nonblank, last_nonblank
      end
      local to_col = math.max(vim.fn.getline(end_line):len(), 1)
      return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
    end

    ai.setup({
      n_lines = 500,
      custom_textobjects = {
        o = ai.gen_spec.treesitter({
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }),
        f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
        c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
        t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
        d = { "%f[%d]%d+" },
        e = {
          { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
          "^().*()$",
        },
        g = ai_buffer,
        u = ai.gen_spec.function_call(),
        U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
      },
    })
  end,
}
