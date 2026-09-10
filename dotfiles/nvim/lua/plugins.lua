vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/windwp/nvim-autopairs",
}, { confirm = false })
require("nvim-treesitter.install").update("all")
require("nvim-autopairs").setup()

-- colorscheme
vim.pack.add({ "https://github.com/folke/tokyonight.nvim" })
vim.cmd.colorscheme("tokyonight-night")

-- mini
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
    "ruff", -- python
    "ty",
    "jedi_language_server",
    "tinymist", -- typst
    "clangd",   -- C/C++
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
  "https://github.com/benomahony/uv.nvim", -- python
}, { confirm = false })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "uv",
  once = true,
  callback = function()
    require("uv").setup({})
  end,
})

vim.pack.add({
  {
    src = "https://github.com/chomosuke/typst-preview.nvim",
    version = "v1.4.2",
  },
})

-- open watch for typst
vim.api.nvim_create_autocmd("FileType", {
  pattern = "typst",
  once = true,
  callback = function(args)
    local pdf = args.file:gsub("%.typ$", ".pdf")
    vim.fn.jobstart({ "typst", "watch", args.file, pdf })
    vim.fn.jobstart({ "sh", "-c", 'until [ -f "' .. pdf .. '" ]; do sleep 0.1; done; exec zathura "' .. pdf .. '"' },
      require("typst-preview").setup({ open_cmd = "chromium --app=%s" })
      { detached = true })
  end,
})
