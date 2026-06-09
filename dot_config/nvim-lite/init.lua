-- nvim-lite: practical Neovim setup with no external plugins.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

pcall(vim.loader.enable)

local opt = vim.opt

opt.termguicolors = true
opt.background = "dark"
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 400
opt.confirm = true

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.linebreak = true
opt.list = true
opt.listchars = {
  tab = "> ",
  trail = ".",
  extends = ">",
  precedes = "<",
  nbsp = "+",
}
opt.fillchars = {
  eob = " ",
  fold = " ",
  foldopen = "v",
  foldclose = ">",
  foldsep = " ",
  diff = "-",
  msgsep = "-",
}

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.breakindent = true

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

opt.splitbelow = true
opt.splitright = true
opt.equalalways = false

opt.completeopt = { "menuone", "noselect" }
opt.pumheight = 12
opt.wildmenu = true
opt.wildmode = { "longest:full", "full" }
opt.wildignore:append({
  "*.o",
  "*.obj",
  "*.pyc",
  "*.class",
  "*.aux",
  "*.out",
  "*.toc",
  ".git",
  "node_modules",
  "dist",
  "build",
  "target",
})

opt.showmode = false
opt.showcmd = false
opt.cmdheight = 1
opt.ruler = false
pcall(function()
  opt.laststatus = 3
end)
opt.showtabline = 2

opt.foldmethod = "indent"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --smart-case"
  opt.grepformat = "%f:%l:%c:%m"
end

vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 25
vim.g.netrw_altv = 1

local palette = {
  bg = "#282a36",
  bg_dark = "#191a21",
  bg_float = "#21222c",
  selection = "#44475a",
  comment = "#6272a4",
  fg = "#f8f8f2",
  fg_dim = "#d6d6d1",
  cyan = "#8be9fd",
  green = "#50fa7b",
  orange = "#ffb86c",
  pink = "#ff79c6",
  purple = "#bd93f9",
  red = "#ff5555",
  yellow = "#f1fa8c",
}

local function set_hl(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

local function apply_dracula()
  vim.cmd.highlight("clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd.syntax("reset")
  end
  vim.g.colors_name = "nvim_lite_dracula"

  local groups = {
    Normal = { fg = palette.fg, bg = palette.bg },
    NormalNC = { fg = palette.fg_dim, bg = palette.bg },
    NormalFloat = { fg = palette.fg, bg = palette.bg_float },
    FloatBorder = { fg = palette.purple, bg = palette.bg_float },
    WinSeparator = { fg = palette.selection, bg = palette.bg },
    VertSplit = { fg = palette.selection, bg = palette.bg },
    ColorColumn = { bg = palette.bg_float },
    Cursor = { fg = palette.bg, bg = palette.fg },
    CursorLine = { bg = palette.bg_float },
    CursorLineNr = { fg = palette.yellow, bg = palette.bg_float, bold = true },
    LineNr = { fg = palette.comment },
    SignColumn = { fg = palette.comment, bg = palette.bg },
    FoldColumn = { fg = palette.comment, bg = palette.bg },
    Folded = { fg = palette.comment, bg = palette.bg_float },
    EndOfBuffer = { fg = palette.bg },
    NonText = { fg = palette.comment },
    Whitespace = { fg = palette.selection },

    Visual = { bg = palette.selection },
    Search = { fg = palette.bg, bg = palette.yellow },
    IncSearch = { fg = palette.bg, bg = palette.orange },
    CurSearch = { fg = palette.bg, bg = palette.orange, bold = true },
    MatchParen = { fg = palette.cyan, bg = palette.selection, bold = true },

    Pmenu = { fg = palette.fg, bg = palette.bg_float },
    PmenuSel = { fg = palette.bg, bg = palette.purple, bold = true },
    PmenuSbar = { bg = palette.selection },
    PmenuThumb = { bg = palette.purple },

    StatusLine = { fg = palette.fg, bg = palette.bg_float },
    StatusLineNC = { fg = palette.comment, bg = palette.bg_dark },
    TabLine = { fg = palette.comment, bg = palette.bg_dark },
    TabLineSel = { fg = palette.bg, bg = palette.purple, bold = true },
    TabLineFill = { fg = palette.comment, bg = palette.bg_dark },

    Directory = { fg = palette.cyan, bold = true },
    Title = { fg = palette.green, bold = true },
    ErrorMsg = { fg = palette.red, bold = true },
    WarningMsg = { fg = palette.orange, bold = true },
    MoreMsg = { fg = palette.green },
    ModeMsg = { fg = palette.yellow },
    Question = { fg = palette.cyan },
    Todo = { fg = palette.bg, bg = palette.yellow, bold = true },

    Comment = { fg = palette.comment, italic = true },
    Constant = { fg = palette.purple },
    String = { fg = palette.yellow },
    Character = { fg = palette.yellow },
    Number = { fg = palette.purple },
    Boolean = { fg = palette.purple },
    Float = { fg = palette.purple },
    Identifier = { fg = palette.fg },
    Function = { fg = palette.green },
    Statement = { fg = palette.pink },
    Conditional = { fg = palette.pink },
    Repeat = { fg = palette.pink },
    Label = { fg = palette.pink },
    Operator = { fg = palette.pink },
    Keyword = { fg = palette.pink },
    Exception = { fg = palette.pink },
    PreProc = { fg = palette.pink },
    Include = { fg = palette.pink },
    Define = { fg = palette.pink },
    Macro = { fg = palette.pink },
    PreCondit = { fg = palette.pink },
    Type = { fg = palette.cyan },
    StorageClass = { fg = palette.pink },
    Structure = { fg = palette.cyan },
    Typedef = { fg = palette.cyan },
    Special = { fg = palette.green },
    SpecialChar = { fg = palette.pink },
    Tag = { fg = palette.pink },
    Delimiter = { fg = palette.fg },
    SpecialComment = { fg = palette.comment, italic = true },
    Underlined = { fg = palette.cyan, underline = true },
    Ignore = { fg = palette.comment },
    Error = { fg = palette.red },

    DiffAdd = { fg = palette.green, bg = "#1f3d2b" },
    DiffChange = { fg = palette.orange, bg = "#3a2f24" },
    DiffDelete = { fg = palette.red, bg = "#3a2028" },
    DiffText = { fg = palette.yellow, bg = "#4a3f24", bold = true },

    DiagnosticError = { fg = palette.red },
    DiagnosticWarn = { fg = palette.orange },
    DiagnosticInfo = { fg = palette.cyan },
    DiagnosticHint = { fg = palette.green },
    DiagnosticOk = { fg = palette.green },
    DiagnosticSignError = { fg = palette.red, bg = palette.bg },
    DiagnosticSignWarn = { fg = palette.orange, bg = palette.bg },
    DiagnosticSignInfo = { fg = palette.cyan, bg = palette.bg },
    DiagnosticSignHint = { fg = palette.green, bg = palette.bg },
    DiagnosticVirtualTextError = { fg = palette.red, bg = "#3a2028" },
    DiagnosticVirtualTextWarn = { fg = palette.orange, bg = "#3a2f24" },
    DiagnosticVirtualTextInfo = { fg = palette.cyan, bg = "#20343d" },
    DiagnosticVirtualTextHint = { fg = palette.green, bg = "#1f3d2b" },
    DiagnosticUnderlineError = { sp = palette.red, undercurl = true },
    DiagnosticUnderlineWarn = { sp = palette.orange, undercurl = true },
    DiagnosticUnderlineInfo = { sp = palette.cyan, undercurl = true },
    DiagnosticUnderlineHint = { sp = palette.green, undercurl = true },

    NvimLiteStatusModeNormal = { fg = palette.bg, bg = palette.purple, bold = true },
    NvimLiteStatusModeInsert = { fg = palette.bg, bg = palette.green, bold = true },
    NvimLiteStatusModeVisual = { fg = palette.bg, bg = palette.pink, bold = true },
    NvimLiteStatusModeReplace = { fg = palette.bg, bg = palette.red, bold = true },
    NvimLiteStatusModeCommand = { fg = palette.bg, bg = palette.yellow, bold = true },
    NvimLiteStatusModeTerminal = { fg = palette.bg, bg = palette.cyan, bold = true },
    NvimLiteStatusModeOther = { fg = palette.bg, bg = palette.orange, bold = true },
    NvimLiteStatusFile = { fg = palette.fg, bg = palette.bg_float, bold = true },
    NvimLiteStatusInfo = { fg = palette.cyan, bg = palette.bg_float },
    NvimLiteStatusMuted = { fg = palette.comment, bg = palette.bg_float },
    NvimLiteStatusError = { fg = palette.red, bg = palette.bg_float, bold = true },
    NvimLiteStatusWarn = { fg = palette.orange, bg = palette.bg_float, bold = true },
    NvimLiteStatusHint = { fg = palette.green, bg = palette.bg_float, bold = true },
    NvimLiteStatusInactive = { fg = palette.comment, bg = palette.bg_dark },

    NvimLiteTabActive = { fg = palette.bg, bg = palette.purple, bold = true },
    NvimLiteTabInactive = { fg = palette.fg_dim, bg = palette.bg_dark },
    NvimLiteTabModified = { fg = palette.orange, bg = palette.bg_dark, bold = true },
    NvimLiteTabFill = { fg = palette.comment, bg = palette.bg_dark },
  }

  for group, spec in pairs(groups) do
    set_hl(group, spec)
  end

  local treesitter_groups = {
    ["@variable"] = { fg = palette.fg },
    ["@variable.builtin"] = { fg = palette.purple, italic = true },
    ["@constant"] = { fg = palette.purple },
    ["@constant.builtin"] = { fg = palette.purple },
    ["@string"] = { fg = palette.yellow },
    ["@string.escape"] = { fg = palette.pink },
    ["@character"] = { fg = palette.yellow },
    ["@number"] = { fg = palette.purple },
    ["@boolean"] = { fg = palette.purple },
    ["@function"] = { fg = palette.green },
    ["@function.builtin"] = { fg = palette.cyan },
    ["@constructor"] = { fg = palette.cyan },
    ["@keyword"] = { fg = palette.pink },
    ["@keyword.function"] = { fg = palette.pink },
    ["@keyword.operator"] = { fg = palette.pink },
    ["@operator"] = { fg = palette.pink },
    ["@type"] = { fg = palette.cyan },
    ["@type.builtin"] = { fg = palette.cyan, italic = true },
    ["@property"] = { fg = palette.fg },
    ["@field"] = { fg = palette.fg },
    ["@parameter"] = { fg = palette.orange },
    ["@punctuation"] = { fg = palette.fg_dim },
    ["@comment"] = { fg = palette.comment, italic = true },
    ["@tag"] = { fg = palette.pink },
    ["@tag.attribute"] = { fg = palette.green },
    ["@tag.delimiter"] = { fg = palette.fg_dim },
  }

  for group, spec in pairs(treesitter_groups) do
    set_hl(group, spec)
  end
end

apply_dracula()

local signs = {
  Error = "E",
  Warn = "W",
  Hint = "H",
  Info = "I",
}

for type, text in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = text, texthl = hl, numhl = "" })
end

vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  virtual_text = {
    spacing = 2,
    prefix = "~",
  },
  float = {
    border = "rounded",
    source = "if_many",
  },
})

pcall(function()
  vim.o.winborder = "rounded"
end)

local nvim_lite = {}
_G.NvimLite = nvim_lite

local mode_map = {
  n = { "NORMAL", "Normal" },
  no = { "O-PENDING", "Normal" },
  nov = { "O-PENDING", "Normal" },
  noV = { "O-PENDING", "Normal" },
  ["no\22"] = { "O-PENDING", "Normal" },
  niI = { "NORMAL", "Normal" },
  niR = { "NORMAL", "Normal" },
  niV = { "NORMAL", "Normal" },
  nt = { "NORMAL", "Normal" },
  v = { "VISUAL", "Visual" },
  vs = { "VISUAL", "Visual" },
  V = { "V-LINE", "Visual" },
  Vs = { "V-LINE", "Visual" },
  ["\22"] = { "V-BLOCK", "Visual" },
  ["\22s"] = { "V-BLOCK", "Visual" },
  s = { "SELECT", "Visual" },
  S = { "S-LINE", "Visual" },
  ["\19"] = { "S-BLOCK", "Visual" },
  i = { "INSERT", "Insert" },
  ic = { "INSERT", "Insert" },
  ix = { "INSERT", "Insert" },
  R = { "REPLACE", "Replace" },
  Rc = { "REPLACE", "Replace" },
  Rx = { "REPLACE", "Replace" },
  Rv = { "V-REPLACE", "Replace" },
  Rvc = { "V-REPLACE", "Replace" },
  Rvx = { "V-REPLACE", "Replace" },
  c = { "COMMAND", "Command" },
  cv = { "EX", "Command" },
  ce = { "EX", "Command" },
  r = { "PROMPT", "Other" },
  rm = { "MORE", "Other" },
  ["r?"] = { "CONFIRM", "Other" },
  ["!"] = { "SHELL", "Terminal" },
  t = { "TERM", "Terminal" },
}

local severity = vim.diagnostic.severity
local diagnostic_order = {
  { severity.ERROR, "E", "NvimLiteStatusError" },
  { severity.WARN, "W", "NvimLiteStatusWarn" },
  { severity.INFO, "I", "NvimLiteStatusInfo" },
  { severity.HINT, "H", "NvimLiteStatusHint" },
}

local function escape_statusline(text)
  return tostring(text):gsub("%%", "%%%%"):gsub("\n", " ")
end

local function buf_name(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return "[No Name]"
  end
  local relative = vim.fn.fnamemodify(name, ":.")
  if relative ~= "" and not relative:match("^%.%.") and #relative <= #name then
    return relative
  end
  return vim.fn.fnamemodify(name, ":~")
end

local function short_name(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return "[No Name]"
  end
  local tail = vim.fn.fnamemodify(name, ":t")
  if tail == "" then
    return vim.fn.fnamemodify(name, ":~")
  end
  return tail
end

local function status_segment(group, text)
  if text == nil or text == "" then
    return ""
  end
  return "%#" .. group .. "# " .. escape_statusline(text) .. " "
end

local function diagnostics_segment(buf)
  local parts = {}
  for _, item in ipairs(diagnostic_order) do
    local count = #vim.diagnostic.get(buf, { severity = item[1] })
    if count > 0 then
      parts[#parts + 1] = "%#" .. item[3] .. "# " .. item[2] .. ":" .. count .. " "
    end
  end
  return table.concat(parts)
end

local function lsp_segment(buf)
  local lsp = package.loaded["vim.lsp"]
  if not lsp then
    return ""
  end

  local clients = {}
  if lsp.get_clients then
    clients = lsp.get_clients({ bufnr = buf })
  elseif lsp.get_active_clients then
    clients = lsp.get_active_clients({ bufnr = buf })
  end

  if #clients == 0 then
    return ""
  end

  local names = {}
  for _, client in ipairs(clients) do
    names[#names + 1] = client.name
  end
  table.sort(names)
  return "LSP " .. table.concat(names, ",")
end

function nvim_lite.statusline()
  local win = tonumber(vim.g.statusline_winid) or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    return ""
  end

  local buf = vim.api.nvim_win_get_buf(win)
  local active = win == vim.api.nvim_get_current_win()

  if not active then
    return table.concat({
      "%#NvimLiteStatusInactive# ",
      escape_statusline(short_name(buf)),
      " %=",
      escape_statusline(vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "plain"),
      " ",
    })
  end

  local mode = mode_map[vim.fn.mode(1)] or { "NORMAL", "Other" }
  local mode_group = "NvimLiteStatusMode" .. mode[2]
  local name = buf_name(buf)
  local flags = {}

  if vim.bo[buf].modified then
    flags[#flags + 1] = "+"
  end
  if vim.bo[buf].readonly or not vim.bo[buf].modifiable then
    flags[#flags + 1] = "RO"
  end

  local filetype = vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "plain"
  local encoding = vim.bo[buf].fileencoding ~= "" and vim.bo[buf].fileencoding or vim.o.encoding
  local format = vim.bo[buf].fileformat
  local lsp = lsp_segment(buf)

  return table.concat({
    status_segment(mode_group, mode[1]),
    status_segment("NvimLiteStatusFile", name .. (#flags > 0 and " " .. table.concat(flags, " ") or "")),
    diagnostics_segment(buf),
    "%#NvimLiteStatusMuted#%=",
    status_segment("NvimLiteStatusMuted", lsp),
    status_segment("NvimLiteStatusInfo", filetype),
    status_segment("NvimLiteStatusMuted", encoding .. "[" .. format .. "]"),
    "%#NvimLiteStatusFile# %l:%c %p%% ",
  })
end

local function tab_is_modified(tab)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].modified then
      return true
    end
  end
  return false
end

function nvim_lite.tabline()
  local current = vim.api.nvim_get_current_tabpage()
  local parts = { "%#NvimLiteTabFill#" }

  for index, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local active = tab == current
    local group = active and "NvimLiteTabActive" or "NvimLiteTabInactive"
    local win = vim.api.nvim_tabpage_get_win(tab)
    local buf = vim.api.nvim_win_get_buf(win)
    local label = short_name(buf)
    local modified = tab_is_modified(tab)
    local wins = #vim.api.nvim_tabpage_list_wins(tab)

    parts[#parts + 1] = "%" .. index .. "T"
    parts[#parts + 1] = "%#" .. group .. "# "
    parts[#parts + 1] = tostring(index) .. ":" .. escape_statusline(label)
    if wins > 1 then
      parts[#parts + 1] = " [" .. wins .. "]"
    end
    if modified then
      parts[#parts + 1] = active and " +" or "%#NvimLiteTabModified# +"
    end
    parts[#parts + 1] = " "
    parts[#parts + 1] = "%#NvimLiteTabFill# "
  end

  parts[#parts + 1] = "%T%=%#NvimLiteTabFill# tabs:" .. tostring(#vim.api.nvim_list_tabpages()) .. " "
  return table.concat(parts)
end

opt.statusline = "%!v:lua.NvimLite.statusline()"
opt.tabline = "%!v:lua.NvimLite.tabline()"

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

map("n", "<leader>w", "<cmd>write<cr>", "Write buffer")
map("n", "<leader>q", "<cmd>quit<cr>", "Quit window")
map("n", "<leader>Q", "<cmd>qa<cr>", "Quit all")
map("n", "<leader>h", "<cmd>nohlsearch<cr>", "Clear search highlight")
map("n", "<leader>e", "<cmd>Explore<cr>", "Open netrw")
map("n", "<leader>f", ":find ", "Find file")
map("n", "<leader>g", ":grep ", "Project grep")
map("n", "<leader>o", "<cmd>only<cr>", "Only window")

map("n", "<leader>bn", "<cmd>bnext<cr>", "Next buffer")
map("n", "<leader>bp", "<cmd>bprevious<cr>", "Previous buffer")
map("n", "<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")

map("n", "<leader>tn", "<cmd>tabnew<cr>", "New tab")
map("n", "<leader>tc", "<cmd>tabclose<cr>", "Close tab")
map("n", "<leader>to", "<cmd>tabonly<cr>", "Only tab")
map("n", "<leader>tl", "<cmd>tabnext<cr>", "Next tab")
map("n", "<leader>th", "<cmd>tabprevious<cr>", "Previous tab")
map("n", "<S-l>", "<cmd>tabnext<cr>", "Next tab")
map("n", "<S-h>", "<cmd>tabprevious<cr>", "Previous tab")

map("n", "<C-h>", "<C-w>h", "Move to left window")
map("n", "<C-j>", "<C-w>j", "Move to lower window")
map("n", "<C-k>", "<C-w>k", "Move to upper window")
map("n", "<C-l>", "<C-w>l", "Move to right window")

map("n", "<A-h>", "<cmd>vertical resize -2<cr>", "Narrow window")
map("n", "<A-l>", "<cmd>vertical resize +2<cr>", "Widen window")
map("n", "<A-j>", "<cmd>resize -2<cr>", "Shorten window")
map("n", "<A-k>", "<cmd>resize +2<cr>", "Heighten window")

map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
map("n", "<leader>dl", vim.diagnostic.open_float, "Line diagnostics")
map("n", "<leader>dq", vim.diagnostic.setloclist, "Diagnostics list")

map("v", "<", "<gv", "Indent left")
map("v", ">", ">gv", "Indent right")
map("v", "J", ":move '>+1<cr>gv=gv", "Move selection down")
map("v", "K", ":move '<-2<cr>gv=gv", "Move selection up")

map("n", "J", "mzJ`z", "Join lines")
map("n", "<C-d>", "<C-d>zz", "Half page down")
map("n", "<C-u>", "<C-u>zz", "Half page up")
map("n", "n", "nzzzv", "Next search")
map("n", "N", "Nzzzv", "Previous search")
map("t", "<Esc><Esc>", [[<C-\><C-n>]], "Terminal normal mode")

vim.api.nvim_create_user_command("Scratch", function()
  vim.cmd.enew()
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "hide"
  vim.bo.swapfile = false
  vim.bo.filetype = "markdown"
end, { desc = "Open a scratch buffer" })

vim.api.nvim_create_user_command("Format", function()
  local ok, lsp = pcall(require, "vim.lsp")
  if ok and lsp.buf and lsp.buf.format then
    lsp.buf.format({ async = true })
  else
    vim.notify("No LSP formatter is available", vim.log.levels.WARN)
  end
end, { desc = "Format with built-in LSP" })

local augroup = vim.api.nvim_create_augroup("NvimLite", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 180 })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "help", "qf", "man", "checkhealth" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", {
      buffer = event.buf,
      silent = true,
      desc = "Close window",
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "gitcommit", "markdown", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "make" },
  callback = function()
    vim.opt_local.expandtab = false
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  command = "tabdo wincmd =",
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup,
  command = "checktime",
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})
