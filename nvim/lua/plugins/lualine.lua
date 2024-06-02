return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections.lualine_z = {
        {
          function()
            local lsps = vim.lsp.get_clients({ bufnr = vim.fn.bufnr() })
            -- local icon = require("nvim-web-devicons").get_icon_by_filetype(vim.api.nvim_buf_get_option(0, "filetype"))
            if lsps and #lsps > 0 then
              local names = {}
              for _, lsp in ipairs(lsps) do
                table.insert(names, lsp.name)
              end
              return string.format("%s", table.concat(names, ", "))
            else
              return ""
            end
          end,
          on_click = function()
            vim.api.nvim_command("LspInfo")
          end,
        },
      }
    end,
  },
}
