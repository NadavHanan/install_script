vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/windwp/nvim-autopairs"
}, { confirm = false })
require("nvim-treesitter.install").update("all")
require("nvim-autopairs").setup()

vim.pack.add({
  "https://github.com/echasnovski/mini.nvim",
}, { confirm = false })

require("mini.statusline").setup({ use_icons = true })
require("mini.ai").setup()      --b q f l n
require("mini.comment").setup() --gc gcc

-- navigation
vim.pack.add({
  "https://github.com/stevearc/oil.nvim",           -- oil
  "https://github.com/nvim-tree/nvim-web-devicons", -- picker icons
  "https://github.com/ibhagwan/fzf-lua",            -- picker
  "https://github.com/chentoast/marks.nvim",        -- mark
}, { confirm = false })
require("fzf-lua")

require("oil").setup({
  skip_confirm_for_simple_edits = true,
  view_options = {
    is_always_hidden = function(name, _)
      return name == ".."
    end,
  }
})

-- lsp
vim.pack.add({
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",
}, { confirm = false })

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "ruff",                 -- python
    "tinymist",             -- typst
    "clangd",               -- C/C++
    "bash-language-server", --bash
  },
})

-- autocmp
vim.pack.add({
  "https://github.com/saghen/blink.cmp",
}, { confirm = false, version = "1.*" })
require("blink.cmp").setup({
  completion = {
    documentation = {
      auto_show = true,
    },
  },
  -- default blink keymaps
  keymap = {
    preset = 'enter',
    ['<S-Tab>'] = { 'select_prev', 'fallback' },
    ['<Tab>'] = { 'select_next', 'fallback' },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
  fuzzy = { implementation = "lua" },
})

-- lang
vim.pack.add({
  "https://github.com/benomahony/uv.nvim",           -- python
  "https://github.com/chomosuke/typst-preview.nvim", -- typst
}, { confirm = false })

require("typst-preview").setup({
  opts = {
    open_cmd = "chromium --app=%s",
  },
})

require("uv").setup({
  opts = {
    picker_integration = true,
  },
})

-- colorscheme
vim.pack.add({ "https://github.com/folke/tokyonight.nvim" })
vim.cmd.colorscheme("tokyonight-night")
