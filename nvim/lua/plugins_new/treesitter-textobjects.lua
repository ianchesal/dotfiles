-- nvim-treesitter-textobjects, `main` branch (paired with treesitter main).
-- LazyVim only configured the `move` module; the keymaps below are LazyVim's
-- move keys (from its treesitter spec) ported onto the main-branch API:
-- require("nvim-treesitter-textobjects.move").<method>(query, "textobjects").
return {
  src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
  policy = { mode = "commit" },
  priority = 21,
  config = function()
    require("nvim-treesitter-textobjects").setup({
      move = {
        set_jumps = true, -- record jumps in the jumplist
      },
    })

    local moves = {
      goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
      goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
      goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
      goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
    }

    for method, keymaps in pairs(moves) do
      for key, query in pairs(keymaps) do
        local part = query:gsub("@", ""):gsub("%..*", "")
        part = part:sub(1, 1):upper() .. part:sub(2)
        local desc = (key:sub(1, 1) == "[" and "Prev " or "Next ")
          .. part
          .. (key:sub(2, 2) == key:sub(2, 2):upper() and " End" or " Start")
        vim.keymap.set({ "n", "x", "o" }, key, function()
          -- In diff mode, ]c/[c must keep their builtin change-hunk motion
          if vim.wo.diff and key:find("[cC]") then
            return vim.cmd("normal! " .. key)
          end
          require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
        end, { desc = desc, silent = true })
      end
    end
  end,
}
