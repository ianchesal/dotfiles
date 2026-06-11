-- folke/which-key.nvim — displays a popup with available keybindings.
-- Priority 25: loads early so group labels are registered before other
-- plugins' keymaps fire.
--
-- Sources:
--   - .snapshot/opts.lua [which-key.nvim] — preset, spec (group defs)
--   - LazyVim editor.lua at HEAD           — which-key block (key bodies)
--   - .snapshot/keys.lua [which-key.nvim]  — <leader>? and <c-w><space>
--   - Old user keymaps.lua                 — <leader>l LSP group (rewritten)
--
-- Dropped groups (plugins not ported):
--   <leader>d  debug     — nvim-dap cluster dropped
--   <leader>dp profiler  — nvim-dap cluster dropped
--   <leader>t  test      — neotest dropped
--   <leader>gh hunks     — gitsigns dropped; no <leader>gh* maps exist
--
-- Kept groups: all others from the snapshot spec.
-- User <leader>l rewrite:
--   ll (:Lazy)        → DROPPED (no lazy.nvim)
--   lh (:LazyHealth)  → <cmd>checkhealth<cr>
--   lg, li, lm, lr    → :LspLog, :LspInfo, :Mason, :LspRestart
--   (nvim-lspconfig 0.12+ provides :LspInfo/:LspLog/:LspRestart)

return {
  src = "https://github.com/folke/which-key.nvim",
  policy = { mode = "commit" },
  priority = 25,
  config = function()
    local wk = require("which-key")

    wk.setup({
      preset = "helix",
      defaults = {},
      spec = {
        {
          mode = { "n", "x" },
          { "<leader><tab>", group = "tabs" },
          { "<leader>b", group = "buffer" },
          { "<leader>c", group = "code" },
          { "<leader>f", group = "file/find" },
          { "<leader>g", group = "git" },
          { "<leader>q", group = "quit/session" },
          { "<leader>s", group = "search" },
          { "<leader>u", group = "ui" },
          { "<leader>x", group = "diagnostics/quickfix" },
          { "[", group = "prev" },
          { "]", group = "next" },
          { "g", group = "goto" },
          { "gs", group = "surround" },
          { "z", group = "fold" },
          {
            "<leader>w",
            group = "windows",
            proxy = "<c-w>",
            expand = function()
              return require("which-key.extras").expand.win()
            end,
          },
          { "gx", desc = "Open with system app" },
        },
      },
    })

    -- Buffer-local keymaps popup
    vim.keymap.set("n", "<leader>?", function()
      require("which-key").show({ global = false })
    end, { desc = "Buffer Keymaps (which-key)" })

    -- Window hydra mode
    vim.keymap.set("n", "<c-w><space>", function()
      require("which-key").show({ keys = "<c-w>", loop = true })
    end, { desc = "Window Hydra Mode (which-key)" })

    -- User <leader>l LSP group (rewritten from old keymaps.lua)
    -- :LazyHealth → :checkhealth  (no lazy.nvim in this setup)
    -- :Lazy        → DROPPED
    -- :LspLog/:LspInfo/:LspRestart/:Mason — provided by nvim-lspconfig 0.12+
    wk.add({
      { "<leader>l", group = "lsp", icon = "" },
      { "<leader>lg", "<cmd>LspLog<cr>", desc = "Open LSP logs" },
      { "<leader>lh", "<cmd>checkhealth<cr>", desc = "Health diagnostics" },
      { "<leader>li", "<cmd>LspInfo<cr>", desc = "Open LspInfo interface" },
      { "<leader>lm", "<cmd>Mason<cr>", desc = "Open Mason management interface" },
      { "<leader>lr", "<cmd>LspRestart<cr>", desc = "Restart all LSPs" },
    })
  end,
}
