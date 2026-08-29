vim.g.mapleader = " "
vim.g.have_nerd_font = true

require("options")
require("keymaps")
require("autocmd")
require("plugins")
require("vim._core.ui2").enable()

