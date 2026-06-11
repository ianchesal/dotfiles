-- nvim-mini/mini.icons — icon provider, priority 14 (UI dep, loads early).
-- Must be configured before other plugins that call nvim-web-devicons.
--
-- Sources:
--   - .snapshot/opts.lua [mini.icons]       — file and filetype customizations
--
-- IMPORTANT: MiniIcons.mock_nvim_web_devicons() is called after setup so that
-- plugins requesting nvim-web-devicons (which is NOT installed) get mini.icons
-- responses instead.

return {
  src = "https://github.com/nvim-mini/mini.icons",
  policy = { mode = "commit" },
  priority = 14,
  config = function()
    require("mini.icons").setup({
      file = {
        [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
        [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
        [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
        [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
        ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
        ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
      },
      filetype = {
        dotenv = { glyph = "", hl = "MiniIconsYellow" },
      },
    })

    -- Shim nvim-web-devicons API so plugins that require it get mini.icons data
    MiniIcons.mock_nvim_web_devicons()
  end,
}
