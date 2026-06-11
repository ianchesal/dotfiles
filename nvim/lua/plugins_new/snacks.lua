-- folke/snacks.nvim — priority 15 (before other UI so Snacks global is
-- available for the LSP keymaps set up in lspconfig.lua).
--
-- Sources:
--   - .snapshot/opts.lua [snacks.nvim] — resolved merged opts
--   - LazyVim ui.lua, util.lua at HEAD (bigfile/quickfile/terminal/scratch/
--     notification snacks blocks)
--   - LazyVim extras/editor/snacks_picker.lua at HEAD (all picker keymaps;
--     <leader>sg/<leader>sG/<leader>//<leader><space>/<leader>ff/<leader>fF
--     re-resolved as plain Snacks.picker calls — LazyVim.pick abstraction
--     is gone)
--   - Old user nvim/lua/plugins/snacks.lua (scroll disabled, picker
--     hidden=true, explorer+indent disabled, custom IRC dashboard header)

return {
  src = "https://github.com/folke/snacks.nvim",
  policy = { mode = "commit" },
  priority = 15,
  config = function()
    -- stylua: ignore
    require("snacks").setup({
      bigfile    = { enabled = true },
      quickfile  = { enabled = true },
      input      = { enabled = true },
      notifier   = { enabled = true },
      scope      = { enabled = true },
      -- User override: scroll disabled (smooth-scroll effect unwanted)
      scroll     = { enabled = false },
      -- User override: indent guides disabled
      indent     = { enabled = false },
      -- Statuscolumn managed separately (options.lua)
      statuscolumn = { enabled = false },
      words      = { enabled = true },
      -- toggle.map left at default (LazyVim.safe_keymap_set shim gone)
      toggle     = { enabled = true },

      -- User override: explorer disabled
      explorer   = { enabled = false },

      -- terminal: keep LazyVim's window-nav bindings in terminal mode
      terminal = {
        win = {
          keys = {
            nav_h = { "<C-h>", function(self)
              return self:is_floating() and "<c-h>" or vim.schedule(function() vim.cmd.wincmd("h") end)
            end, desc = "Go to Left Window", expr = true, mode = "t" },
            nav_j = { "<C-j>", function(self)
              return self:is_floating() and "<c-j>" or vim.schedule(function() vim.cmd.wincmd("j") end)
            end, desc = "Go to Lower Window", expr = true, mode = "t" },
            nav_k = { "<C-k>", function(self)
              return self:is_floating() and "<c-k>" or vim.schedule(function() vim.cmd.wincmd("k") end)
            end, desc = "Go to Upper Window", expr = true, mode = "t" },
            nav_l = { "<C-l>", function(self)
              return self:is_floating() and "<c-l>" or vim.schedule(function() vim.cmd.wincmd("l") end)
            end, desc = "Go to Right Window", expr = true, mode = "t" },
            -- LazyVim's <C-/>/<c-_> hide keys intentionally NOT ported: the
            -- user deleted all Snacks.terminal toggles (tmux person).
          },
        },
      },

      picker = {
        enabled = true,
        -- User override: show hidden/dotfiles, respect .gitignore
        sources = {
          files = { hidden = true, ignored = false },
          grep  = { hidden = true, ignored = false },
        },
        -- Extra picker actions (from snacks_picker extra + user sidekick action)
        actions = {
          -- Jump to picker match with flash.nvim labels
          flash = function(picker)
            require("flash").jump({
              pattern = "^",
              label = { after = { 0, 0 } },
              search = {
                mode = "search",
                exclude = {
                  function(win)
                    return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                  end,
                },
              },
              action = function(match)
                local idx = picker.list:row2idx(match.pos[1])
                picker.list:_move(idx, true, true)
              end,
            })
          end,
          -- Send selected file(s) to sidekick CLI
          sidekick_send = function(picker)
            local items = picker:selected({ fallback = true })
            for _, item in ipairs(items) do
              local path = item.file or item.text
              if path then
                require("sidekick.cli").send({ msg = path })
              end
            end
          end,
          -- Toggle between repo root and cwd
          toggle_cwd = function(picker)
            local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
            local current = picker:cwd()
            -- simple toggle: if already at cwd, try to find git root
            local git_root = vim.fs.root(0, ".git")
            local target = (current == cwd and git_root) and git_root or cwd
            picker:set_cwd(target)
            picker:find()
          end,
          -- Open picker results in trouble
          trouble_open = function(...)
            return require("trouble.sources.snacks").actions.trouble_open.action(...)
          end,
        },
        win = {
          input = {
            keys = {
              ["<a-a>"] = { "sidekick_send", mode = { "n", "i" } },
              ["<a-c>"] = { "toggle_cwd",    mode = { "n", "i" } },
              ["<a-s>"] = { "flash",         mode = { "n", "i" } },
              ["<a-t>"] = { "trouble_open",  mode = { "n", "i" } },
              s         = { "flash" },
            },
          },
        },
      },

      dashboard = {
        enabled = true,
        preset = {
          -- User's custom IRC-logo header (from old snacks.lua)
          -- See: https://patorjk.com/software/taag/#p=display&v=0&f=ANSI%20Shadow&t=IRC
          header = "██╗██████╗  ██████╗\n██║██╔══██╗██╔════╝\n██║██████╔╝██║     \n██║██╔══██╗██║     \n██║██║  ██║╚██████╗\n╚═╝╚═╝  ╚═╝ ╚═════╝\n        ",
          -- pick() resolved: dashboard uses Snacks.picker directly
          pick = function(cmd, opts)
            return Snacks.picker.pick(cmd, opts)
          end,
          -- stylua: ignore
          ---@type snacks.dashboard.Item[]
          keys = {
            { icon = " ", key = "f", desc = "Find File",     action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File",      action = ":ene | startinsert" },
            { icon = " ", key = "p", desc = "Projects",      action = ":lua Snacks.picker.projects()" },
            { icon = " ", key = "g", desc = "Find Text",     action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files",  action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "Config",        action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "q", desc = "Quit",          action = ":qa" },
          },
        },
      },
    })

    -- ── Keymaps ──────────────────────────────────────────────────────────

    -- Notifications
    vim.keymap.set("n", "<leader>n", function()
      Snacks.picker.notifications()
    end, { desc = "Notification History" })
    vim.keymap.set("n", "<leader>un", function()
      Snacks.notifier.hide()
    end, { desc = "Dismiss All Notifications" })

    -- Scratch buffers (from LazyVim util.lua)
    vim.keymap.set("n", "<leader>.", function()
      Snacks.scratch()
    end, { desc = "Toggle Scratch Buffer" })
    vim.keymap.set("n", "<leader>S", function()
      Snacks.scratch.select()
    end, { desc = "Select Scratch Buffer" })
    -- <leader>dps (profiler scratch) intentionally NOT ported: the whole
    -- <leader>d debug group was dropped with the dap cluster.

    -- Buffers / quick navigation
    vim.keymap.set("n", "<leader>,", function()
      Snacks.picker.buffers()
    end, { desc = "Buffers" })
    vim.keymap.set("n", "<leader>/", function()
      Snacks.picker.grep()
    end, { desc = "Grep (Root Dir)" })
    vim.keymap.set("n", "<leader>:", function()
      Snacks.picker.command_history()
    end, { desc = "Command History" })
    vim.keymap.set("n", "<leader><space>", function()
      Snacks.picker.files()
    end, { desc = "Find Files (Root Dir)" })

    -- Find (<leader>f*)
    vim.keymap.set("n", "<leader>fb", function()
      Snacks.picker.buffers()
    end, { desc = "Buffers" })
    vim.keymap.set("n", "<leader>fB", function()
      Snacks.picker.buffers({ hidden = true, nofile = true })
    end, { desc = "Buffers (all)" })
    vim.keymap.set("n", "<leader>fc", function()
      Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
    end, { desc = "Find Config File" })
    vim.keymap.set("n", "<leader>ff", function()
      Snacks.picker.files()
    end, { desc = "Find Files (Root Dir)" })
    vim.keymap.set("n", "<leader>fF", function()
      Snacks.picker.files({ root = false })
    end, { desc = "Find Files (cwd)" })
    vim.keymap.set("n", "<leader>fg", function()
      Snacks.picker.git_files()
    end, { desc = "Find Files (git-files)" })
    vim.keymap.set("n", "<leader>fr", function()
      Snacks.picker.recent()
    end, { desc = "Recent" })
    vim.keymap.set("n", "<leader>fR", function()
      Snacks.picker.recent({ filter = { cwd = true } })
    end, { desc = "Recent (cwd)" })
    vim.keymap.set("n", "<leader>fp", function()
      Snacks.picker.projects()
    end, { desc = "Projects" })

    -- Git (<leader>g*) — snacks git pickers (hunk signs/overlay live in mini-diff.lua)
    vim.keymap.set("n", "<leader>gd", function()
      Snacks.picker.git_diff()
    end, { desc = "Git Diff (hunks)" })
    vim.keymap.set("n", "<leader>gD", function()
      Snacks.picker.git_diff({ base = "origin", group = true })
    end, { desc = "Git Diff (origin)" })
    vim.keymap.set("n", "<leader>gs", function()
      Snacks.picker.git_status()
    end, { desc = "Git Status" })
    vim.keymap.set("n", "<leader>gS", function()
      Snacks.picker.git_stash()
    end, { desc = "Git Stash" })
    vim.keymap.set("n", "<leader>gi", function()
      Snacks.picker.gh_issue()
    end, { desc = "GitHub Issues (open)" })
    vim.keymap.set("n", "<leader>gI", function()
      Snacks.picker.gh_issue({ state = "all" })
    end, { desc = "GitHub Issues (all)" })
    vim.keymap.set("n", "<leader>gp", function()
      Snacks.picker.gh_pr()
    end, { desc = "GitHub Pull Requests (open)" })
    vim.keymap.set("n", "<leader>gP", function()
      Snacks.picker.gh_pr({ state = "all" })
    end, { desc = "GitHub Pull Requests (all)" })

    -- Search / grep (<leader>s*)
    vim.keymap.set("n", "<leader>sb", function()
      Snacks.picker.lines()
    end, { desc = "Buffer Lines" })
    vim.keymap.set("n", "<leader>sB", function()
      Snacks.picker.grep_buffers()
    end, { desc = "Grep Open Buffers" })
    vim.keymap.set("n", "<leader>sg", function()
      Snacks.picker.grep()
    end, { desc = "Grep (Root Dir)" })
    vim.keymap.set("n", "<leader>sG", function()
      Snacks.picker.grep({ root = false })
    end, { desc = "Grep (cwd)" })
    -- <leader>sp (Snacks.picker.lazy, "Search for Plugin Spec") intentionally
    -- NOT ported: it introspects lazy.nvim plugin specs, which are gone.
    vim.keymap.set({ "n", "x" }, "<leader>sw", function()
      Snacks.picker.grep_word()
    end, { desc = "Visual selection or word (Root Dir)" })
    vim.keymap.set({ "n", "x" }, "<leader>sW", function()
      Snacks.picker.grep_word({ root = false })
    end, { desc = "Visual selection or word (cwd)" })
    vim.keymap.set("n", '<leader>s"', function()
      Snacks.picker.registers()
    end, { desc = "Registers" })
    vim.keymap.set("n", "<leader>s/", function()
      Snacks.picker.search_history()
    end, { desc = "Search History" })
    vim.keymap.set("n", "<leader>sa", function()
      Snacks.picker.autocmds()
    end, { desc = "Autocmds" })
    vim.keymap.set("n", "<leader>sc", function()
      Snacks.picker.command_history()
    end, { desc = "Command History" })
    vim.keymap.set("n", "<leader>sC", function()
      Snacks.picker.commands()
    end, { desc = "Commands" })
    vim.keymap.set("n", "<leader>sd", function()
      Snacks.picker.diagnostics()
    end, { desc = "Diagnostics" })
    vim.keymap.set("n", "<leader>sD", function()
      Snacks.picker.diagnostics_buffer()
    end, { desc = "Buffer Diagnostics" })
    vim.keymap.set("n", "<leader>sh", function()
      Snacks.picker.help()
    end, { desc = "Help Pages" })
    vim.keymap.set("n", "<leader>sH", function()
      Snacks.picker.highlights()
    end, { desc = "Highlights" })
    vim.keymap.set("n", "<leader>si", function()
      Snacks.picker.icons()
    end, { desc = "Icons" })
    vim.keymap.set("n", "<leader>sj", function()
      Snacks.picker.jumps()
    end, { desc = "Jumps" })
    vim.keymap.set("n", "<leader>sk", function()
      Snacks.picker.keymaps()
    end, { desc = "Keymaps" })
    vim.keymap.set("n", "<leader>sl", function()
      Snacks.picker.loclist()
    end, { desc = "Location List" })
    vim.keymap.set("n", "<leader>sM", function()
      Snacks.picker.man()
    end, { desc = "Man Pages" })
    vim.keymap.set("n", "<leader>sm", function()
      Snacks.picker.marks()
    end, { desc = "Marks" })
    vim.keymap.set("n", "<leader>sR", function()
      Snacks.picker.resume()
    end, { desc = "Resume" })
    vim.keymap.set("n", "<leader>sq", function()
      Snacks.picker.qflist()
    end, { desc = "Quickfix List" })
    vim.keymap.set("n", "<leader>su", function()
      Snacks.picker.undo()
    end, { desc = "Undotree" })

    -- UI
    vim.keymap.set("n", "<leader>uC", function()
      Snacks.picker.colorschemes()
    end, { desc = "Colorschemes" })
  end,
}
