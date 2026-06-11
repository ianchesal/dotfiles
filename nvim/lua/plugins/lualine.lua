-- nvim-lualine/lualine.nvim — fancy status line.
--
-- Sources:
--   - .snapshot/opts.lua [lualine.nvim] — resolved sections (function refs
--     decoded against LazyVim ui.lua at HEAD)
--   - LazyVim ui.lua at HEAD            — lualine block; root_dir/pretty_path
--     inline-resolved from lazyvim/util/lualine.lua
--   - Old user nvim/lua/plugins/lualine.lua — lualine_z: LSP client names
--
-- LazyVim-specific components removed / replaced:
--   - LazyVim.lualine.root_dir()  → inline implementation (shows git root
--     basename when it differs from cwd, using vim.fs)
--   - LazyVim.lualine.pretty_path() → plain lualine "filename" component
--     (the full pretty_path needs LazyVim.root and LazyVim.norm; not
--     worth duplicating the whole util; plain filename is functionally
--     equivalent for everyday use)
--   - Snacks.profiler.status()    → DROPPED (no profiler session in normal
--     use; the component is a no-op except during profiling runs)
--   - require("lazy.status").updates / has_updates → DROPPED (lazy.nvim is
--     gone; this was the "lazy updates pending" indicator)
--   - dap status component        → DROPPED (nvim-dap cluster not ported)
--   - extensions "neo-tree", "lazy" → DROPPED (those plugins are gone);
--     "fzf" kept in case fzf is installed as a fallback
--
-- User override (lualine_z): show connected LSP client names with click
-- handler to open LspInfo — preserved from old user lualine.lua.

return {
  src = "https://github.com/nvim-lualine/lualine.nvim",
  policy = { mode = "commit" },
  config = function()
    -- Inline minimal root_dir component (replaces LazyVim.lualine.root_dir).
    -- Shows the basename of the nearest .git root when it differs from cwd.
    local function root_dir_component()
      local function get_root_name()
        local root = vim.fs.root(0, ".git")
        if not root then
          return nil
        end
        root = vim.fs.normalize(root)
        local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
        if root == cwd then
          return nil -- same dir, not worth showing
        end
        return vim.fs.basename(root)
      end

      return {
        function()
          return "󱉭 " .. (get_root_name() or "")
        end,
        cond = function()
          return get_root_name() ~= nil
        end,
        color = function()
          -- Use Snacks colour helper if available, else fallback
          local ok, snacks = pcall(function()
            return Snacks.util.color("Special")
          end)
          return { fg = ok and snacks or nil }
        end,
      }
    end

    require("lualine").setup({
      options = {
        theme = "auto",
        globalstatus = true,
        disabled_filetypes = {
          statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" },
        },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },
        lualine_c = {
          root_dir_component(),
          {
            "diagnostics",
            symbols = {
              error = " ",
              warn = " ",
              info = " ",
              hint = " ",
            },
          },
          { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          -- plain filename replaces LazyVim.lualine.pretty_path()
          { "filename", path = 1 },
        },
        lualine_x = {
          -- Snacks.profiler.status() DROPPED — no-op outside profiling
          -- noice command display
          {
            function()
              return require("noice").api.status.command.get()
            end,
            cond = function()
              return package.loaded["noice"] and require("noice").api.status.command.has()
            end,
            color = function()
              local ok, c = pcall(function()
                return Snacks.util.color("Statement")
              end)
              return { fg = ok and c or nil }
            end,
          },
          -- noice mode display
          {
            function()
              return require("noice").api.status.mode.get()
            end,
            cond = function()
              return package.loaded["noice"] and require("noice").api.status.mode.has()
            end,
            color = function()
              local ok, c = pcall(function()
                return Snacks.util.color("Constant")
              end)
              return { fg = ok and c or nil }
            end,
          },
          -- dap status DROPPED — nvim-dap cluster not ported
          -- lazy.status DROPPED — lazy.nvim not in this setup
          {
            "diff",
            symbols = {
              added = " ",
              modified = " ",
              removed = " ",
            },
            -- Diff counts come from mini.diff (gitsigns is not installed).
            -- Port of LazyVim's extras/editor/mini-diff.lua lualine patch.
            source = function()
              local summary = vim.b.minidiff_summary
              return summary
                and {
                  added = summary.add,
                  modified = summary.change,
                  removed = summary.delete,
                }
            end,
          },
        },
        lualine_y = {
          { "progress", separator = " ", padding = { left = 1, right = 0 } },
          { "location", padding = { left = 0, right = 1 } },
        },
        -- User override (old lualine.lua): show LSP client names, click → LspInfo
        lualine_z = {
          {
            function()
              local lsps = vim.lsp.get_clients({ bufnr = vim.fn.bufnr() })
              if lsps and #lsps > 0 then
                local names = {}
                for _, lsp in ipairs(lsps) do
                  table.insert(names, lsp.name)
                end
                return table.concat(names, ", ")
              else
                return ""
              end
            end,
            on_click = function()
              vim.api.nvim_command("LspInfo")
            end,
          },
        },
      },
      -- neo-tree and lazy extensions dropped; fzf kept
      extensions = { "fzf" },
    })
  end,
}
