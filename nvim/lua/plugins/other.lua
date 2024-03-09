return {
  -- https://github.com/rgroli/other.nvim
  "rgroli/other.nvim",
  lazy = false,
  config = function()
    require("other-nvim").setup({
      mappings = {
        "livewire",
        "angular",
        "laravel",
        "rails",
        "golang",
      },
    })
  end,
}
