-- nvim-treesitter, pinned to the maintained `main` branch (a deliberate
-- migration off the frozen `master`). The main branch has a completely
-- different API: no module system, no configs.setup(); highlighting and
-- indentation are enabled per-buffer instead.
--
-- Parser list resolved from the LazyVim snapshot (.snapshot/parsers.lua),
-- deduped. Folds are intentionally NOT configured: folding is handled by
-- mkview persistence, not treesitter.
local parsers = {
  "bash",
  "c",
  "diff",
  "dockerfile",
  "fish",
  "git_config",
  "git_rebase",
  "gitignore",
  "graphql",
  "hcl",
  "html",
  "http",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "jsonc",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "printf",
  "python",
  "query",
  "regex",
  "ruby",
  "terraform",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

return {
  src = "https://github.com/nvim-treesitter/nvim-treesitter",
  policy = { mode = "commit" },
  priority = 20,
  config = function()
    local TS = require("nvim-treesitter")
    -- Defaults are fine: install_dir = stdpath("data") .. "/site"
    TS.setup({})

    -- Cache of installed parsers, refreshed after async installs finish.
    local installed = {}
    local function refresh()
      installed = {}
      for _, lang in ipairs(TS.get_installed("parsers")) do
        installed[lang] = true
      end
    end
    refresh()

    -- Install any missing parsers. install() is async; register a completion
    -- callback instead of :wait()-ing so startup is never blocked.
    local missing = vim.tbl_filter(function(lang)
      return not installed[lang]
    end, parsers)
    if #missing > 0 then
      TS.install(missing, { summary = true }):await(refresh)
    end

    -- The main branch does not enable any features itself. Turn on
    -- highlighting and indentation per-buffer for installed languages.
    -- disable lists carried over from the old master-branch config:
    -- highlight disabled for csv, indent disabled for ruby.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not (lang and installed[lang]) then
          return
        end
        if lang ~= "csv" then
          pcall(vim.treesitter.start, ev.buf)
        end
        if lang ~= "ruby" then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
