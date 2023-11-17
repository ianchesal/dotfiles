-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- Start with Copilot disabled. I can't think of a better way to do this.
vim.cmd(":Copilot disable")
