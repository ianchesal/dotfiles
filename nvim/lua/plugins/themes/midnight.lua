return {
  'dasupradyumna/midnight.nvim', -- https://github.com/dasupradyumna/midnight.nvim
  lazy = false,
  priority = 1000,
  config = function()
    require('midnight').setup()
  end
}
