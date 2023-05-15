-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Some OS detectors
local is_wsl = (function()
  local output = vim.fn.systemlist("uname -r")
  return not not string.find(output[1] or "", "WSL")
end)()
local is_mac = vim.fn.has("macunix") == 1
local is_linux = not is_wsl and not is_mac

require("lazy").setup({
  -- General philsophy here is to only put plugins here that do not require any configuration. If there's
  -- any configuration required it should go in its own file under lua/plugins so if it fails to load it
  -- doesn't take down loading the rest of this file.
  --
  -- For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins

  -- Git related plugins
  "tpope/vim-fugitive",
  "tpope/vim-rhubarb",

  -- Detect tabstop and shiftwidth automatically
  "tpope/vim-sleuth",

  -- Useful plugin to show you pending keybinds.
  { "folke/which-key.nvim",          opts = {} },

  -- "gc" to comment visual regions/lines
  { "numToStr/Comment.nvim",         opts = {} },

  -- Fuzzy Finder (files, lsp, etc)
  { "nvim-telescope/telescope.nvim", version = "*", dependencies = { "nvim-lua/plenary.nvim" } },
  { import = "plugins" },
}, {})

-- [[ Setting options ]]
-- See `:help vim.o`

-- Set highlight on search
vim.o.hlsearch = true

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = "unnamedplus"
if is_wsl then
  -- This is NeoVim's recommended way to solve clipboard sharing if you use WSL
  -- See: https://github.com/neovim/neovim/wiki/FAQ#how-to-use-the-windows-clipboard-from-wsl
  vim.cmd([[
  let g:clipboard = {
  \   'name': 'WslClipboard',
  \   'copy': {
  \      '+': 'clip.exe',
  \      '*': 'clip.exe',
  \    },
  \   'paste': {
  \      '+': 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  \      '*': 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  \   },
  \   'cache_enabled': 0,
  \ }
  ]])
end

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- I had this in my old vimrc
vim.o.complete = ".,w,b,u,t,i,kspell"
vim.o.visualbell = true

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- Keep minimum rows/cols on screen at all times
vim.o.scrolloff = 5
vim.o.sidescrolloff = 5

-- Split below and right
vim.o.splitbelow = true
vim.o.splitright = true

-- No wrap
vim.o.wrap = false

-- EXPERIMENTAL: Stuff I'm trying out
if vim.fn.has("nvim-0.9.0") == 1 then
  vim.o.splitkeep = "screen"
end

-- [[ Basic Keymaps ]]

vim.cmd([[noremap ; :]])

-- I am too old to re-learn how to yank and paste a whole line in vim
vim.cmd([[noremap Y Y]])

-- Allow me to typo q and w
vim.cmd([[
cnoreabbrev <expr> W ((getcmdtype() is# ':' && getcmdline() is# 'W')?('w'):('W'))
cnoreabbrev <expr> Q ((getcmdtype() is# ':' && getcmdline() is# 'Q')?('q'):('Q'))
cnoreabbrev <expr> WQ ((getcmdtype() is# ':' && getcmdline() is# 'WQ')?('wq'):('WQ'))
cnoreabbrev <expr> Wq ((getcmdtype() is# ':' && getcmdline() is# 'Wq')?('wq'):('Wq'))
]])

-- ESC clears search highlights
vim.cmd([[nnoremap <silent> <Esc> <Esc>:noh<CR>]])

-- nvim 0.9.x turns editorconfig support by default, turn it off by doing:
-- vim.g.editorconfig = false

-- disable netrw at the very top level
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Don't care about these
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require("telescope").setup({
  defaults = {
    mappings = {
      i = {
        ["<C-u>"] = false,
        ["<C-d>"] = false,
        -- Close file finder on single press of Esc key
        ["<Esc>"] = require("telescope.actions").close,
      },
    },
  },
})

-- Enable telescope fzf native, if installed
pcall(require("telescope").load_extension, "fzf")

-- See `:help telescope.builtin`
vim.keymap.set("n", "<leader>?", require("telescope.builtin").oldfiles, { desc = "[?] Find recently opened files" })
vim.keymap.set("n", "<leader><space>", require("telescope.builtin").buffers, { desc = "[ ] Find existing buffers" })
vim.keymap.set("n", "<Tab>", require("telescope.builtin").buffers, { desc = "[ ] Find existing buffers" })
vim.keymap.set("n", "<leader>/", function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
    winblend = 10,
    previewer = false,
  }))
end, { desc = "[/] Fuzzily search in current buffer" })

vim.keymap.set("n", "<leader>gf", require("telescope.builtin").git_files, { desc = "Search [G]it [F]iles" })
vim.keymap.set("n", "<leader>sf", require("telescope.builtin").find_files, { desc = "[S]earch [F]iles" })
-- I've got ff in my brain now for [F]ind [F]iles
vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "[F]ind [F]iles" })
vim.keymap.set("n", "<leader>sw", require("telescope.builtin").grep_string, { desc = "[S]earch current [W]ord" })
vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "[S]earch by [G]rep" })
vim.keymap.set("n", "<leader>sd", require("telescope.builtin").diagnostics, { desc = "[S]earch [D]iagnostics" })
vim.keymap.set("n", "<leader>sk", require("telescope.builtin").keymaps, { desc = "[S]earch [K]eymaps" })

-- Toggle autoformatting off/on
vim.keymap.set("n", "<leader>af", "<cmd>KickstartFormatToggle<CR>", { desc = "Toggle auto-formatting", noremap = true })

-- Git
vim.keymap.set("n", "<leader>gg", "<cmd>Git<CR>", { desc = "git fugitive", noremap = true })

-- null-ls
vim.keymap.set("n", "<leader>ln", "<cmd>NullLsInfo<CR>", { desc = "NullLS Information" })

-- nvim-tree
vim.keymap.set("n", "<c-n>", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle nvim-tree", noremap = true })

-- Buffers
vim.keymap.set("n", "<leader>bf", vim.lsp.buf.format, { desc = "Format current buffer", noremap = true })
vim.keymap.set("n", "<leader>bn", "<cmd>enew<CR>", { desc = "Create a new empty buffer", noremap = true })
vim.keymap.set("n", "<leader>bd", "<cmd>Bdelete<CR>", { desc = "Delete current buffer", noremap = true })
vim.keymap.set("n", "<leader>bw", "<cmd>Bwipeout<CR>", { desc = "Wipeout current buffer", noremap = true })

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
require("nvim-treesitter.configs").setup({
  -- Add languages to be installed here that you want installed for treesitter
  ensure_installed = {
    "bash",
    "c",
    "comment",
    "cpp",
    "git_rebase",
    "gitcommit",
    "gitignore",
    "go",
    "hcl",
    "html",
    "json",
    "jsonnet",
    "lua",
    "make",
    "markdown",
    "python",
    "ruby",
    "rust",
    "terraform",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
  },

  -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
  auto_install = false,

  highlight = { enable = true },
  indent = { enable = true, disable = { "python" } },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<c-space>",
      node_incremental = "<c-space>",
      scope_incremental = "<c-s>",
      node_decremental = "<M-space>",
    },
  },
  textobjects = {
    select = {
      lookahead = true,
      -- Automatically jump forward to textobj, similar to targets.vim, enable = true
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]]"] = "@class.outer",
      },
      goto_next_end = {
        ["]M"] = "@function.outer",
        ["]["] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
      },
      goto_previous_end = {
        ["[M"] = "@function.outer",
        ["[]"] = "@class.outer",
      },
    },
    swap = {
      enable = true,
      swap_next = {
        ["<leader>a"] = "@parameter.inner",
      },
      swap_previous = {
        ["<leader>A"] = "@parameter.inner",
      },
    },
  },
})

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- Treesitter Endwise Setup
require("nvim-treesitter.configs").setup({
  endwise = {
    enable = true,
  },
})

-- LSP settings.
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(client, bufnr)
  -- NOTE: Remember that lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself
  -- many times.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local nmap = function(keys, func, desc)
    if desc then
      desc = "LSP: " .. desc
    end

    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
  end

  -- local format = function()
  --   vim.lsp.buf.format({ id = client.id, async = true })
  -- end
  -- vim.keymap.set({ "x", "n" }, "gq", format, { buffer = bufnr, desc = "Format current buffer" })

  nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
  nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

  nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
  nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
  nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
  nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
  nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
  nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

  -- See `:help K` for why this keymap
  nmap("K", vim.lsp.buf.hover, "Hover Documentation")
  nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

  -- Lesser used LSP functionality
  nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
  nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
  nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
  nmap("<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, "[W]orkspace [L]ist Folders")

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
    vim.lsp.buf.format()
  end, { desc = "Format current buffer with LSP" })
end

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
local servers = {
  bashls = {
    filetypes = { "sh", "zsh" },
  },
  clangd = {},
  cssls = {},
  denols = {},
  dockerls = {},
  docker_compose_language_service = {},
  -- gopls = {},
  helm_ls = {},
  jsonls = {},
  jsonnet_ls = {},
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
  marksman = {},
  pyright = {},
  -- rust_analyzer = {},
  solargraph = {},
  taplo = {},
  terraformls = {
    filetypes = { "terraform", "tf", "tfvars" },
  },
  tsserver = {},
  yamlls = {},
}

-- Setup neovim lua configuration
require("neodev").setup()

-- Setup null-ls
local null_ls = require("null-ls")
local formatting = null_ls.builtins.formatting
local lint = null_ls.builtins.diagnostics
local hover = null_ls.builtins.hover
local null_ls_sources = {
  -- webdev stuff
  formatting.deno_fmt,
  formatting.prettier.with({ filetypes = { "html", "markdown", "css" } }),
  -- Lua
  -- formatting.stylua,
  -- cpp
  -- formatting.clang_format,
  -- Terraform
  formatting.terraform_fmt,
  lint.terraform_validate,
  -- Ruby w/Rubocop
  -- formatting.rubocop,
  -- formatting.rubyfmt,
  -- lint.rubocop,
  -- YAML
  -- formatting.yq,
  -- Bash, zsh
  -- formatting.shfmt,
  -- lint.shellcheck,
  -- Packer
  formatting.packer,
  -- I dun spel gud
  -- hover.dictionary,
}
-- Format on save from here: https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Formatting-on-save#sync-formatting
-- local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
null_ls.setup({
  debug = true,
  sources = null_ls_sources,
  -- you can reuse a shared lspconfig on_attach callback here
  -- Uncomment this is you want to format everything on save
  --[[ on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })
    end
  end, ]]
})

-- Auto-format Terraform on save
vim.cmd([[ autocmd BufWritePre *.tf lua vim.lsp.buf.format() ]])
vim.cmd([[ autocmd BufWritePre *.tfvars lua vim.lsp.buf.format() ]])

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require("mason-lspconfig")

mason_lspconfig.setup({
  ensure_installed = vim.tbl_keys(servers),
})

mason_lspconfig.setup_handlers({
  function(server_name)
    require("lspconfig")[server_name].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
    })
  end,
})

-- Do any server-specific setup here
local lspconfig = require("lspconfig")
lspconfig.solargraph.setup({
  settings = {
    solargraph = {
      diagnostics = true,
    },
  },
})

lspconfig.terraformls.setup({
  on_attach = function(client, _)
    client.server_capabilities.documentFormattingProvider = false
  end,
})

-- nvim-cmp setup
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local cmp = require("cmp")
local luasnip = require("luasnip")

luasnip.config.setup({})
-- For use with friendly-snippets
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete({}),
    ["<CR>"] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "copilot" },
    { name = "path" },
  },
})

-- autopairs setup for cmp
cmp.event:on("confirm.done", cmp_autopairs.on_confirm_done())

-- vim: ts=2 sts=2 sw=2 et
