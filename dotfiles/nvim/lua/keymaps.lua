-- keymap func
local map = function(keys, func, desc, mode)
  mode = mode or "n"
  desc = desc or ""
  vim.keymap.set(mode, keys, func, { desc = desc })
end

-- navigation
map("<leader>j", "<C-d>zz", "down")
map("<leader>k", "<C-u>zz", "up")

map("<leader>g", function()
  if not vim.b.gmode_enabled then
    map("j", "gj")
    map("k", "gk")
    vim.b.gmode_enabled = true
  else
    map("j", "j")
    map("k", "k")
    vim.b.gmode_enabled = false
  end
end)

-- :normal
map("<leader>n", ":norm ", "normal command", "v")

-- oil
map("-", "<CMD>Oil<CR>", "open perent dir with oil")

-- clear search highlights with <Esc>
map("<Esc>", "<cmd>nohlsearch<CR>")

-- lsp
map("<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")

-- write & run
map("<leader>r", function()
  vim.cmd("write")
  -- corrently there are uv, c/c++ and sh run commands
  local ft = vim.bo.filetype
  if ft == "python" then
    vim.cmd("UVRunFile")
  elseif ft == "cpp" or ft == "c" then
    local file = vim.fn.expand("%:p")
    local output = vim.fn.expand("%:p:r")
    local cmd = string.format("gcc '%s' -o '%s' && '%s'", file, output, output)
    vim.cmd("botright 10new")
    vim.cmd("startinsert")
    vim.cmd("term " .. cmd)
  elseif ft == "r" then
    vim.cmd("!Rscript --vanilla %")
  elseif ft == "sh" then
    vim.cmd("!cat % | sh")
  end
end, "save and run")

-- "https://menisadi.github.io/hebneovim/"
-- hebrew mode
-- Defining the different cursors in a table
local guicursor_ltr = table.concat({
  "n-v-c:block",   -- normal/visual/cmdline: block
  "i-ci-ve:ver25", -- insert/insert-cmd/visual-exclude: vertical bar (steady)
  "r-cr:hor20",    -- replace modes: underline
  "o:hor50",       -- operator-pending
}, ",")

local guicursor_rtl = table.concat({
  "n-v-c:block",   -- normal/visual/cmdline: block
  "i-ci-ve:hor20", -- insert becomes underline (steady) for RTL
  "r-cr:hor20",
  "o:hor50",
}, ",")

-- Default to LTR cursor shapes
vim.o.guicursor = guicursor_ltr
vim.b.completion = true
map("<leader>h", function()
  if not vim.b.hebrew_mode_enabled then
    vim.opt_local.keymap = "hebrew"
    vim.opt_local.iminsert = 1
    vim.opt_local.imsearch = 1
    vim.opt_local.rightleft = true
    vim.b.hebrew_mode_enabled = true
    vim.o.guicursor = guicursor_rtl
    vim.b.completion = false
    vim.notify("Hebrew mode: ON")
  else
    vim.opt_local.keymap = ""
    vim.opt_local.iminsert = 0
    vim.opt_local.imsearch = 0
    vim.opt_local.rightleft = false
    vim.b.hebrew_mode_enabled = false
    vim.o.guicursor = guicursor_ltr
    vim.b.completion = true
    vim.notify("Hebrew mode: OFF")
  end
end)
