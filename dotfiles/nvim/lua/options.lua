local opt = vim.opt

opt.swapfile = false
opt.mouse = "a"
opt.backspace = "indent,eol,start"
-- Consider - as part of keyword
opt.iskeyword:append("-")

-- Line Numbers
opt.number = true
opt.relativenumber = true

-- Search Settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true

-- Appearance
opt.termguicolors = true
vim.diagnostic.config({ virtual_text = true })
vim.diagnostic.config({ float = { border = "rounded" }, })

-- formatting
opt.expandtab = true
opt.autoindent = true
opt.tabstop = 2
opt.shiftwidth = 2
vim.bo.softtabstop = 2
opt.listchars = { trail = "·", nbsp = "␣" }

-- Clipboard
opt.clipboard:append("unnamedplus")

-- Consider "-" as part of keyword
opt.iskeyword:append("-")

-- Split Windows
opt.splitright = true
opt.splitbelow = true

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
  },
  virtual_text = true, -- show inline diagnostics
})
