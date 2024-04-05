return {
  "echasnovski/mini.starter",
  version = false,
  opts = function()
    local starter = require("mini.starter")
    starter.setup({
      items = {
        starter.sections.telescope(),
      },
      content_hooks = {
        starter.gen_hook.adding_bullet(),
        starter.gen_hook.aligning("center", "center"),
      },
    })
  end,
}
