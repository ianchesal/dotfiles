-- LSP setup on the nvim 0.12 native stack: nvim-lspconfig only supplies the
-- per-server config definitions consumed by vim.lsp.config()/vim.lsp.enable().
--
-- Sources: the old user nvim/lua/plugins/nvim-lspconfig.lua merged with the
-- LazyVim snapshot's resolved server settings (.snapshot/opts.lua), keymaps
-- from LazyVim's lsp spec + snacks_picker extra at the locked rev.
--
-- Enabling strategy (no double-enable): mason-lspconfig v2's automatic_enable
-- calls vim.lsp.enable() for every mason-installed server, so this file only
-- enables servers mason does NOT manage (e.g. regols, installed via brew) and
-- lets require("mason-lspconfig").setup() -- called here, after all
-- vim.lsp.config() definitions -- handle the rest, with the explicitly
-- disabled servers excluded.

-- Servers disabled in the snapshot. They go to automatic_enable.exclude so
-- mason-lspconfig never enables them even if their packages are installed
-- (e.g. ts_ls <- typescript-language-server, which mason.lua installs).
-- taplo is excluded deliberately: no TOML LSP wanted, and the work machine's
-- Santa policy blocks the binary anyway.
local disabled_servers = { "solargraph", "standardrb", "stylua", "taplo", "ts_ls", "tsgo", "tsserver" }

local servers = {
  bashls = {},
  denols = {},
  diagnosticls = {},
  docker_compose_language_service = {},
  dockerls = {},
  eslint = {
    -- LazyVim's eslint extra also registered an "eslint: lsp" formatter with
    -- its own format engine; that machinery is gone (conform handles
    -- formatting), so only the server settings are ported.
    settings = {
      format = true,
      workingDirectories = { mode = "auto" },
    },
  },
  helm_ls = {},
  jsonls = {
    -- Lazy-load SchemaStore.nvim schemas when the server starts
    -- (LazyVim json extra).
    before_init = function(_, new_config)
      new_config.settings.json.schemas = new_config.settings.json.schemas or {}
      vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
    end,
    settings = {
      json = {
        format = { enable = true },
        validate = { enable = true },
      },
    },
  },
  jsonnet_ls = {},
  lua_ls = {
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
        codeLens = { enable = true },
        completion = { callSnippet = "Replace" },
        doc = { privateName = { "^_" } },
        hint = {
          enable = true,
          setType = false,
          paramType = true,
          paramName = "Disable",
          semicolon = "Disable",
          arrayIndex = "Disable",
        },
      },
    },
  },
  marksman = {},
  -- regols is not managed by Mason; installed with `brew install kitagry/tap/regols`.
  -- See: https://github.com/kitagry/regols
  regols = {},
  rubocop = {
    -- See: https://docs.rubocop.org/rubocop/usage/lsp.html
    cmd = { "bundle", "exec", "rubocop", "--lsp" },
    -- Port of lspconfig.util.root_pattern("Gemfile", ".git", ".") -- the
    -- trailing "." meant "always attach", hence the cwd fallback.
    root_dir = function(bufnr, on_dir)
      local root = vim.fs.root(bufnr, { "Gemfile", ".git" })
      on_dir(root or vim.fn.getcwd())
    end,
  },
  ruby_lsp = {
    init_options = {
      formatter = "auto",
    },
  },
  sqlls = {},
  terraformls = {},
  vtsls = {
    -- From LazyVim's typescript/vtsls extra. The extra's
    -- _typescript.moveToFileRefactoring client-command handler (interactive
    -- "move to file" destination picker) was lazy/LazyVim-coupled and is not
    -- ported. The javascript settings below are the snapshot-resolved copy of
    -- the typescript ones (LazyVim copied them in its setup hook).
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
    },
    settings = {
      complete_function_calls = true,
      vtsls = {
        enableMoveToFileCodeAction = true,
        autoUseWorkspaceTsdk = true,
        experimental = {
          maxInlayHintLength = 30,
          completion = { enableServerSideFuzzyMatch = true },
        },
      },
      typescript = {
        updateImportsOnFileMove = { enabled = "always" },
        suggest = { completeFunctionCalls = true },
        inlayHints = {
          enumMemberValues = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          parameterNames = { enabled = "literals" },
          parameterTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          variableTypes = { enabled = false },
        },
      },
      javascript = {
        updateImportsOnFileMove = { enabled = "always" },
        suggest = { completeFunctionCalls = true },
        inlayHints = {
          enumMemberValues = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          parameterNames = { enabled = "literals" },
          parameterTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          variableTypes = { enabled = false },
        },
      },
    },
  },
  yamlls = {
    -- yamlls needs to be told we support line folding (LazyVim yaml extra)
    capabilities = {
      textDocument = {
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
      },
    },
    -- Lazy-load SchemaStore.nvim schemas when the server starts.
    before_init = function(_, new_config)
      new_config.settings.yaml.schemas =
        vim.tbl_deep_extend("force", new_config.settings.yaml.schemas or {}, require("schemastore").yaml.schemas())
    end,
    settings = {
      redhat = { telemetry = { enabled = false } },
      yaml = {
        keyOrdering = false,
        format = { enable = true },
        validate = true,
        -- Disable built-in schemaStore support in favor of SchemaStore.nvim
        schemaStore = { enable = false, url = "" },
      },
    },
  },
}

-- Trimmed port of LazyVim.lsp.execute, used by the vtsls keymaps.
local function lsp_execute(opts)
  local buf = vim.api.nvim_get_current_buf()
  local filter = { bufnr = buf }
  if opts.filter then
    filter.name = opts.filter
  end
  local client = vim.lsp.get_clients(filter)[1]
  if not client then
    return
  end
  local params = { command = opts.command, arguments = opts.arguments }
  if opts.open then
    require("trouble").open({ mode = "lsp_command", params = params })
  else
    return client:exec_cmd(vim.tbl_extend("force", params, { title = opts.title }), { bufnr = buf })
  end
end

-- Code action shorthand (port of LazyVim.lsp.action[name]).
local function lsp_action(action)
  return function()
    vim.lsp.buf.code_action({
      apply = true,
      context = { only = { action }, diagnostics = {} },
    })
  end
end

-- LazyVim's LSP keymaps (lsp/init.lua servers["*"].keys at the locked rev,
-- with the snacks_picker extra's overrides for gd/gr/gI/gy and the symbol/
-- call-hierarchy pickers). `has` = required LSP method (textDocument/
-- prefixed when bare), `name` = client-name filter, `enabled` = map-time
-- predicate.
-- stylua: ignore
local lsp_keys = {
  { "<leader>cl", function() Snacks.picker.lsp_config() end, desc = "Lsp Info" },
  { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition", has = "definition" },
  { "gr", function() Snacks.picker.lsp_references() end, desc = "References", nowait = true },
  { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
  { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
  { "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
  { "K", function() return vim.lsp.buf.hover() end, desc = "Hover" },
  { "gK", function() return vim.lsp.buf.signature_help() end, desc = "Signature Help", has = "signatureHelp" },
  { "<c-k>", function() return vim.lsp.buf.signature_help() end, mode = "i", desc = "Signature Help", has = "signatureHelp" },
  { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "x" }, has = "codeAction" },
  { "<leader>cc", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "x" }, has = "codeLens" },
  { "<leader>cC", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", has = "codeLens" },
  { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File", has = { "workspace/didRenameFiles", "workspace/willRenameFiles" } },
  { "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
  { "<leader>cA", lsp_action("source"), desc = "Source Action", has = "codeAction" },
  -- LazyVim gated <leader>co on a live scan of advertised code-action kinds;
  -- simplified here to the capability check + a no-op when unsupported.
  { "<leader>co", lsp_action("source.organizeImports"), desc = "Organize Imports", has = "codeAction" },
  { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", has = "documentHighlight", enabled = function() return Snacks.words.is_enabled() end },
  { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", has = "documentHighlight", enabled = function() return Snacks.words.is_enabled() end },
  { "<a-n>", function() Snacks.words.jump(vim.v.count1, true) end, desc = "Next Reference", has = "documentHighlight", enabled = function() return Snacks.words.is_enabled() end },
  { "<a-p>", function() Snacks.words.jump(-vim.v.count1, true) end, desc = "Prev Reference", has = "documentHighlight", enabled = function() return Snacks.words.is_enabled() end },
  -- LazyVim passed filter = LazyVim.config.kind_filter to the symbol pickers;
  -- dropped with LazyVim (snacks' own defaults apply).
  { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols", has = "documentSymbol" },
  { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols", has = "workspace/symbols" },
  { "gai", function() Snacks.picker.lsp_incoming_calls() end, desc = "C[a]lls Incoming", has = "callHierarchy/incomingCalls" },
  { "gao", function() Snacks.picker.lsp_outgoing_calls() end, desc = "C[a]lls Outgoing", has = "callHierarchy/outgoingCalls" },
  -- vtsls-only keymaps (LazyVim typescript extra)
  {
    -- overrides the generic gD above for vtsls clients
    "gD",
    function()
      local win = vim.api.nvim_get_current_win()
      local params = vim.lsp.util.make_position_params(win, "utf-16")
      lsp_execute({
        command = "typescript.goToSourceDefinition",
        arguments = { params.textDocument.uri, params.position },
        open = true,
      })
    end,
    desc = "Goto Source Definition",
    name = "vtsls",
  },
  {
    "gR",
    function()
      lsp_execute({
        command = "typescript.findAllFileReferences",
        arguments = { vim.uri_from_bufnr(0) },
        open = true,
      })
    end,
    desc = "File References",
    name = "vtsls",
  },
  { "<leader>cM", lsp_action("source.addMissingImports.ts"), desc = "Add missing imports", name = "vtsls" },
  { "<leader>cD", lsp_action("source.fixAll.ts"), desc = "Fix all diagnostics", name = "vtsls" },
  {
    "<leader>cV",
    function()
      lsp_execute({
        title = "Select TypeScript Version",
        filter = "vtsls",
        command = "typescript.selectTypeScriptVersion",
      })
    end,
    desc = "Select TS workspace version",
    name = "vtsls",
  },
}

return {
  src = "https://github.com/neovim/nvim-lspconfig",
  policy = { mode = "commit" },
  priority = 32,
  config = function()
    -- Diagnostics (LazyVim's resolved nvim-lspconfig opts.diagnostics)
    vim.diagnostic.config({
      underline = true,
      update_in_insert = false,
      virtual_text = {
        spacing = 4,
        source = "if_many",
        prefix = "●",
      },
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.HINT] = " ",
          [vim.diagnostic.severity.INFO] = " ",
        },
      },
    })

    -- Diagnostic navigation keymaps (LazyVim config/keymaps.lua). These are
    -- global, not LSP-attached: diagnostics can come from non-LSP sources.
    local function diagnostic_goto(next, severity)
      return function()
        vim.diagnostic.jump({
          count = (next and 1 or -1) * vim.v.count1,
          severity = severity and vim.diagnostic.severity[severity] or nil,
          float = true,
        })
      end
    end
    vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
    vim.keymap.set("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
    vim.keymap.set("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
    vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
    vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
    vim.keymap.set("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
    vim.keymap.set("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

    -- LSP keymaps, buffer-local on attach, gated on server capabilities
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("user_lsp_keymaps", { clear = true }),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
          return
        end
        for _, key in ipairs(lsp_keys) do
          local supported = true
          if key.name and key.name ~= client.name then
            supported = false
          end
          if supported and key.has then
            local methods = type(key.has) == "table" and key.has or { key.has }
            supported = false
            for _, method in ipairs(methods) do
              method = method:find("/") and method or ("textDocument/" .. method)
              if client:supports_method(method) then
                supported = true
                break
              end
            end
          end
          if supported and key.enabled and not key.enabled() then
            supported = false
          end
          if supported then
            vim.keymap.set(key.mode or "n", key[1], key[2], {
              buffer = ev.buf,
              desc = key.desc,
              nowait = key.nowait,
              silent = true,
            })
          end
        end
      end,
    })

    -- Default config for every server
    vim.lsp.config("*", {
      capabilities = {
        workspace = {
          fileOperations = {
            didRename = true,
            willRename = true,
          },
        },
      },
    })

    -- Per-server configs; nvim-lspconfig's shipped defaults merge underneath
    for name, cfg in pairs(servers) do
      vim.lsp.config(name, cfg)
    end

    -- Enable. mason-lspconfig auto-enables everything it manages; servers
    -- outside mason's catalog are enabled directly.
    local ok, mason_map = pcall(function()
      -- INTERNAL API: verify on every mason-lspconfig pin bump (see nvim/pins.json)
      return require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
    end)
    if not ok or type(mason_map) ~= "table" then
      vim.notify(
        "mason-lspconfig internals changed: falling back to vim.lsp.enable() for ALL servers; review lspconfig.lua",
        vim.log.levels.WARN
      )
      -- Fallback: enable every configured server directly (the disabled
      -- servers are not in `servers`, so they stay off) and call setup() with
      -- automatic_enable = false -- a public setting -- so mason-lspconfig
      -- cannot double-enable anything. Trade-off: ensure_installed
      -- auto-install of LSP servers is lost (mason.lua still installs most of
      -- them by package name); servers missing from PATH fail with their own
      -- startup error, which is noisy but debuggable.
      for name in pairs(servers) do
        vim.lsp.enable(name)
      end
      require("mason-lspconfig").setup({ automatic_enable = false })
      return
    end

    local ensure_installed = {}
    for name in pairs(servers) do
      if mason_map[name] then
        table.insert(ensure_installed, name)
      else
        vim.lsp.enable(name)
      end
    end
    table.sort(ensure_installed) -- deterministic order for mason's UI/logs

    -- Register the Mason packages backing these servers so `rake
    -- nvim:mason_prune` keeps them (mason.lua's list doesn't include LSP
    -- servers like marksman/vtsls that mason-lspconfig auto-installs).
    -- Registered only on this success path: the fallback branch above can't
    -- map names, so it leaves "lspconfig" unregistered and prune refuses to run.
    local mason_packages = {}
    for _, name in ipairs(ensure_installed) do
      table.insert(mason_packages, mason_map[name])
    end
    require("pack.mason_desired").register("lspconfig", mason_packages)

    require("mason-lspconfig").setup({
      ensure_installed = ensure_installed,
      automatic_enable = { exclude = disabled_servers },
    })
  end,
}
