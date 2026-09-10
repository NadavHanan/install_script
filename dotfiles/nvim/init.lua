vim.g.mapleader = " "
vim.g.have_nerd_font = true

require("options")
require("plugins")
require("keymaps")
require("autocmd")

require("vim._core.ui2").enable()
