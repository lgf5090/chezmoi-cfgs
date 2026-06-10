-- Full Neovim 0.12+ setup using the built-in vim.pack plugin manager.

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

pcall(vim.loader.enable)

if vim.fn.has("nvim-0.12") == 0 then
  vim.notify("This config expects Neovim 0.12 or newer.", vim.log.levels.ERROR)
end

local opt = vim.opt

opt.termguicolors = true
opt.background = "dark"
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.swapfile = false
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
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 12

opt.showmode = false
opt.showcmd = false
opt.ruler = false
pcall(function()
  opt.laststatus = 3
  opt.winborder = "rounded"
end)

opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --smart-case"
  opt.grepformat = "%f:%l:%c:%m"
end

-- nvim-tree replaces netrw.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local function gh(repo)
  return "https://github.com/" .. repo
end

local plugins = {
  { src = gh("Mofiqul/dracula.nvim"), name = "dracula.nvim" },
  gh("nvim-tree/nvim-web-devicons"),
  gh("nvim-lualine/lualine.nvim"),
  gh("akinsho/bufferline.nvim"),
  gh("nvim-tree/nvim-tree.lua"),
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-telescope/telescope.nvim"),
  gh("nvim-treesitter/nvim-treesitter"),
  gh("windwp/nvim-autopairs"),
  gh("kylechui/nvim-surround"),
  gh("numToStr/Comment.nvim"),
  gh("mbbill/undotree"),
  gh("lukas-reineke/indent-blankline.nvim"),
  gh("lewis6991/gitsigns.nvim"),
  gh("folke/which-key.nvim"),
  gh("folke/trouble.nvim"),

  gh("williamboman/mason.nvim"),
  gh("williamboman/mason-lspconfig.nvim"),
  gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
  gh("jay-babu/mason-nvim-dap.nvim"),
  gh("neovim/nvim-lspconfig"),
  gh("mfussenegger/nvim-jdtls"),

  gh("hrsh7th/nvim-cmp"),
  gh("hrsh7th/cmp-nvim-lsp"),
  gh("hrsh7th/cmp-buffer"),
  gh("hrsh7th/cmp-path"),
  gh("hrsh7th/cmp-cmdline"),
  gh("L3MON4D3/LuaSnip"),
  gh("saadparwaiz1/cmp_luasnip"),
  gh("rafamadriz/friendly-snippets"),

  gh("stevearc/conform.nvim"),
  gh("mfussenegger/nvim-lint"),
  gh("mfussenegger/nvim-dap"),
  gh("rcarriga/nvim-dap-ui"),
  gh("nvim-neotest/nvim-nio"),
}

local pack_enabled = vim.env.NVIM_SKIP_PACK ~= "1"
if pack_enabled and vim.pack then
  local ok, err = pcall(vim.pack.add, plugins, { load = true, confirm = false })
  if not ok then
    vim.schedule(function()
      vim.notify("vim.pack failed: " .. tostring(err), vim.log.levels.ERROR)
    end)
  end
end

vim.api.nvim_create_user_command("PackUpdate", function()
  vim.pack.update()
end, { desc = "Update plugins managed by vim.pack" })

vim.api.nvim_create_user_command("PackList", function()
  vim.print(vim.pack.get())
end, { desc = "List plugins managed by vim.pack" })

local function apply_dracula_fallback()
  local palette = {
    bg = "#282a36",
    bg_dark = "#191a21",
    bg_float = "#21222c",
    selection = "#44475a",
    comment = "#6272a4",
    fg = "#f8f8f2",
    cyan = "#8be9fd",
    green = "#50fa7b",
    orange = "#ffb86c",
    pink = "#ff79c6",
    purple = "#bd93f9",
    red = "#ff5555",
    yellow = "#f1fa8c",
  }

  vim.cmd.highlight("clear")
  vim.g.colors_name = "dracula-fallback"

  local groups = {
    Normal = { fg = palette.fg, bg = palette.bg },
    NormalFloat = { fg = palette.fg, bg = palette.bg_float },
    FloatBorder = { fg = palette.purple, bg = palette.bg_float },
    CursorLine = { bg = palette.bg_float },
    CursorLineNr = { fg = palette.yellow, bold = true },
    LineNr = { fg = palette.comment },
    SignColumn = { fg = palette.comment, bg = palette.bg },
    WinSeparator = { fg = palette.selection },
    Visual = { bg = palette.selection },
    Search = { fg = palette.bg, bg = palette.yellow },
    IncSearch = { fg = palette.bg, bg = palette.orange },
    Pmenu = { fg = palette.fg, bg = palette.bg_float },
    PmenuSel = { fg = palette.bg, bg = palette.purple, bold = true },
    StatusLine = { fg = palette.fg, bg = palette.bg_float },
    StatusLineNC = { fg = palette.comment, bg = palette.bg_dark },
    TabLine = { fg = palette.comment, bg = palette.bg_dark },
    TabLineSel = { fg = palette.bg, bg = palette.purple, bold = true },
    Comment = { fg = palette.comment, italic = true },
    Constant = { fg = palette.purple },
    String = { fg = palette.yellow },
    Number = { fg = palette.purple },
    Boolean = { fg = palette.purple },
    Function = { fg = palette.green },
    Keyword = { fg = palette.pink },
    Statement = { fg = palette.pink },
    Type = { fg = palette.cyan },
    Special = { fg = palette.green },
    DiagnosticError = { fg = palette.red },
    DiagnosticWarn = { fg = palette.orange },
    DiagnosticInfo = { fg = palette.cyan },
    DiagnosticHint = { fg = palette.green },
  }

  for group, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, group, spec)
  end
end

local ok_dracula, dracula = pcall(require, "dracula")
if ok_dracula then
  dracula.setup({
    transparent_bg = false,
    italic_comment = true,
    show_end_of_buffer = false,
    lualine_bg_color = "#21222c",
  })
  pcall(vim.cmd.colorscheme, "dracula")
else
  apply_dracula_fallback()
end

local function setup(module, fn)
  local ok, mod = pcall(require, module)
  if ok then
    fn(mod)
  end
end

setup("nvim-web-devicons", function(devicons)
  devicons.setup({
    color_icons = true,
    default = true,
    strict = true,
  })
end)

setup("lualine", function(lualine)
  lualine.setup({
    options = {
      theme = "dracula",
      globalstatus = true,
      icons_enabled = true,
      component_separators = { left = "|", right = "|" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = {
        statusline = { "NvimTree" },
      },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff" },
      lualine_c = {
        {
          "filename",
          path = 1,
          symbols = { modified = " +", readonly = " RO", unnamed = "[No Name]" },
        },
      },
      lualine_x = {
        {
          "diagnostics",
          sources = { "nvim_diagnostic" },
          symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
        },
        "encoding",
        "fileformat",
        "filetype",
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  })
end)

setup("bufferline", function(bufferline)
  bufferline.setup({
    options = {
      mode = "buffers",
      diagnostics = "nvim_lsp",
      always_show_bufferline = true,
      show_buffer_close_icons = false,
      show_close_icon = false,
      separator_style = "thin",
      numbers = "ordinal",
      offsets = {
        {
          filetype = "NvimTree",
          text = "Files",
          text_align = "center",
          separator = true,
        },
      },
    },
  })
end)

setup("nvim-tree", function(nvim_tree)
  nvim_tree.setup({
    hijack_cursor = true,
    sync_root_with_cwd = true,
    respect_buf_cwd = true,
    update_focused_file = {
      enable = true,
      update_root = true,
    },
    view = {
      width = 34,
      side = "left",
      preserve_window_proportions = true,
    },
    renderer = {
      group_empty = true,
      highlight_git = true,
      highlight_opened_files = "name",
      indent_markers = {
        enable = true,
      },
    },
    filters = {
      dotfiles = false,
      git_ignored = false,
    },
    git = {
      enable = true,
      ignore = false,
      timeout = 500,
    },
    actions = {
      open_file = {
        quit_on_open = false,
        resize_window = true,
      },
    },
  })
end)

setup("telescope", function(telescope)
  telescope.setup({
    defaults = {
      prompt_prefix = "> ",
      selection_caret = "> ",
      path_display = { "truncate" },
      sorting_strategy = "ascending",
      layout_config = {
        prompt_position = "top",
        horizontal = { preview_width = 0.55 },
      },
      mappings = {
        i = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
          ["<C-q>"] = "send_selected_to_qflist",
        },
      },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
    },
  })
end)

setup("nvim-treesitter.configs", function(ts)
  ts.setup({
    ensure_installed = {
      "bash",
      "c",
      "cmake",
      "comment",
      "cpp",
      "c_sharp",
      "css",
      "dockerfile",
      "html",
      "java",
      "javascript",
      "json",
      "lua",
      "markdown",
      "markdown_inline",
      "php",
      "python",
      "rust",
      "sql",
      "toml",
      "tsx",
      "typescript",
      "vim",
      "vimdoc",
      "xml",
      "yaml",
    },
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        scope_incremental = false,
        node_decremental = "<BS>",
      },
    },
  })
end)

setup("nvim-autopairs", function(autopairs)
  autopairs.setup({
    check_ts = true,
    fast_wrap = {},
  })
end)

local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
  local ok_luasnip, luasnip = pcall(require, "luasnip")
  if ok_luasnip then
    local ok_loader, loader = pcall(require, "luasnip.loaders.from_vscode")
    if ok_loader then
      loader.lazy_load()
    end
  end

  cmp.setup({
    snippet = {
      expand = function(args)
        if ok_luasnip then
          luasnip.lsp_expand(args.body)
        end
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<CR>"] = cmp.mapping.confirm({ select = false }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif ok_luasnip and luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif ok_luasnip and luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }),
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "luasnip" },
      { name = "path" },
    }, {
      { name = "buffer", keyword_length = 3 },
    }),
  })

  cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "buffer" },
    },
  })

  cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = "path" },
    }, {
      { name = "cmdline" },
    }),
  })

  local ok_cmp_pairs, cmp_pairs = pcall(require, "nvim-autopairs.completion.cmp")
  if ok_cmp_pairs then
    cmp.event:on("confirm_done", cmp_pairs.on_confirm_done())
  end
end

setup("nvim-surround", function(surround)
  surround.setup({})
end)

setup("Comment", function(comment)
  comment.setup({})
end)

setup("ibl", function(ibl)
  ibl.setup({
    indent = {
      char = "|",
    },
    scope = {
      enabled = true,
      show_start = false,
      show_end = false,
    },
  })
end)

setup("gitsigns", function(gitsigns)
  gitsigns.setup({
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "-" },
      changedelete = { text = "~" },
    },
    current_line_blame = false,
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local function bmap(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
      end
      bmap("n", "]h", gs.next_hunk, "Next git hunk")
      bmap("n", "[h", gs.prev_hunk, "Previous git hunk")
      bmap("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
      bmap("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
      bmap("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
      bmap("n", "<leader>hb", gs.blame_line, "Blame line")
    end,
  })
end)

setup("which-key", function(which_key)
  which_key.setup({
    preset = "modern",
    delay = 350,
  })
  which_key.add({
    { "<leader>b", group = "buffers" },
    { "<leader>d", group = "debug" },
    { "<leader>f", group = "find" },
    { "<leader>h", group = "git hunks" },
    { "<leader>l", group = "lsp" },
    { "<leader>p", group = "packages" },
    { "<leader>r", group = "run" },
    { "<leader>t", group = "tabs/tests" },
    { "<leader>x", group = "diagnostics" },
  })
end)

setup("mason", function(mason)
  mason.setup({
    PATH = "prepend",
    ui = {
      border = "rounded",
      icons = {
        package_installed = "+",
        package_pending = ">",
        package_uninstalled = "-",
      },
    },
  })
end)

local mason_lsp_servers = {
  "lua_ls",
  "rust_analyzer",
  "clangd",
  "cmake",
  "csharp_ls",
  "html",
  "cssls",
  "emmet_language_server",
  "ts_ls",
  "jsonls",
  "yamlls",
  "intelephense",
  "bashls",
  "dockerls",
  "docker_compose_language_service",
  "marksman",
  "taplo",
  "sqlls",
  "jdtls",
}

setup("mason-lspconfig", function(mason_lspconfig)
  mason_lspconfig.setup({
    ensure_installed = mason_lsp_servers,
    automatic_enable = false,
  })
end)

setup("mason-tool-installer", function(tool_installer)
  tool_installer.setup({
    ensure_installed = {
      "stylua",
      "shfmt",
      "shellcheck",
      "prettierd",
      "prettier",
      "eslint_d",
      "clang-format",
      "csharpier",
      "php-cs-fixer",
      "google-java-format",
      "black",
      "isort",
      "markdownlint",
    },
    auto_update = false,
    run_on_start = true,
    start_delay = 3000,
  })
end)

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

local function lsp_on_attach(_, bufnr)
  local function bmap(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  bmap("n", "gd", vim.lsp.buf.definition, "Go to definition")
  bmap("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  bmap("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  bmap("n", "gr", vim.lsp.buf.references, "References")
  bmap("n", "K", vim.lsp.buf.hover, "Hover")
  bmap("n", "<leader>la", vim.lsp.buf.code_action, "Code action")
  bmap("n", "<leader>lr", vim.lsp.buf.rename, "Rename")
  bmap("n", "<leader>ls", vim.lsp.buf.signature_help, "Signature help")
  bmap("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
  bmap("n", "<leader>lq", vim.diagnostic.setloclist, "Diagnostics list")
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp_lsp then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLsp", { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    lsp_on_attach(client, event.buf)
  end,
})

vim.lsp.config("*", {
  capabilities = capabilities,
})

local lsp_server_settings = {
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  },
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        check = { command = "clippy" },
        procMacro = { enable = true },
      },
    },
  },
  clangd = {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--completion-style=detailed",
      "--header-insertion=iwyu",
    },
  },
  csharp_ls = {},
  html = {
    filetypes = { "html", "templ", "blade" },
  },
  cssls = {},
  emmet_language_server = {
    filetypes = {
      "html",
      "css",
      "scss",
      "javascriptreact",
      "typescriptreact",
      "php",
      "blade",
    },
  },
  ts_ls = {},
  jsonls = {},
  yamlls = {},
  intelephense = {
    filetypes = { "php", "blade" },
  },
  bashls = {},
  dockerls = {},
  docker_compose_language_service = {},
  marksman = {},
  taplo = {},
  sqlls = {},
  cmake = {},
}

local lsp_command_overrides = {
  csharp_ls = "csharp-ls",
}

local function lsp_executable(server)
  if lsp_command_overrides[server] then
    return lsp_command_overrides[server]
  end

  local config = vim.lsp.config[server]
  local cmd = config and config.cmd
  if type(cmd) == "table" and type(cmd[1]) == "string" then
    return cmd[1]
  end

  return nil
end

local skipped_lsp = {}
for server, config in pairs(lsp_server_settings) do
  vim.lsp.config(server, config)
  local executable = lsp_executable(server)
  if executable and vim.fn.executable(executable) == 0 then
    skipped_lsp[#skipped_lsp + 1] = server .. " (" .. executable .. ")"
  else
    vim.lsp.enable(server)
  end
end

if #skipped_lsp > 0 then
  vim.schedule(function()
    vim.notify(
      "Skipped LSP servers with missing executables: " .. table.concat(skipped_lsp, ", "),
      vim.log.levels.WARN
    )
  end)
end

local function setup_jdtls()
  local ok_jdtls, jdtls = pcall(require, "jdtls")
  if not ok_jdtls then
    return
  end

  local filename = vim.api.nvim_buf_get_name(0)
  local root_dir = vim.fs.root(filename, { "gradlew", "mvnw", "pom.xml", "build.gradle", "settings.gradle", ".git" })
  if not root_dir then
    return
  end

  local project = vim.fn.fnamemodify(root_dir, ":p:h:t")
  local workspace = vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. project

  jdtls.start_or_attach({
    cmd = { "jdtls", "-data", workspace },
    root_dir = root_dir,
    capabilities = capabilities,
    on_attach = lsp_on_attach,
    settings = {
      java = {
        configuration = {
          updateBuildConfiguration = "interactive",
        },
        format = {
          enabled = true,
        },
      },
    },
  })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = setup_jdtls,
})

setup("conform", function(conform)
  conform.setup({
    formatters_by_ft = {
      lua = { "stylua" },
      rust = { "rustfmt" },
      c = { "clang_format" },
      cpp = { "clang_format" },
      cs = { "csharpier" },
      java = { "google_java_format" },
      html = { "prettierd", "prettier", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },
      scss = { "prettierd", "prettier", stop_after_first = true },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
      yaml = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
      php = { "php_cs_fixer" },
      python = { "isort", "black" },
      sh = { "shfmt" },
      bash = { "shfmt" },
    },
    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 1500, lsp_format = "fallback" }
    end,
  })
end)

vim.api.nvim_create_user_command("FormatToggle", function(args)
  if args.bang then
    vim.b.disable_autoformat = not vim.b.disable_autoformat
    vim.notify("Buffer autoformat: " .. tostring(not vim.b.disable_autoformat))
  else
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify("Global autoformat: " .. tostring(not vim.g.disable_autoformat))
  end
end, {
  bang = true,
  desc = "Toggle autoformat globally or for current buffer with !",
})

setup("lint", function(lint)
  lint.linters_by_ft = {
    javascript = { "eslint_d" },
    javascriptreact = { "eslint_d" },
    typescript = { "eslint_d" },
    typescriptreact = { "eslint_d" },
    sh = { "shellcheck" },
    bash = { "shellcheck" },
    markdown = { "markdownlint" },
  }

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("NvimLint", { clear = true }),
    callback = function()
      lint.try_lint()
    end,
  })
end)

setup("trouble", function(trouble)
  trouble.setup({
    focus = true,
  })
end)

local ok_dap, dap = pcall(require, "dap")
if ok_dap then
  setup("mason-nvim-dap", function(mason_dap)
    mason_dap.setup({
      ensure_installed = { "codelldb", "netcoredbg", "java-debug-adapter", "java-test" },
      automatic_installation = true,
      handlers = {},
    })
  end)

  local ok_dapui, dapui = pcall(require, "dapui")
  if ok_dapui then
    dapui.setup({})
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  end

  dap.adapters.coreclr = {
    type = "executable",
    command = "netcoredbg",
    args = { "--interpreter=vscode" },
  }
  dap.configurations.cs = {
    {
      type = "coreclr",
      name = "Launch .NET",
      request = "launch",
      program = function()
        return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
      end,
    },
  }

  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = "codelldb",
      args = { "--port", "${port}" },
    },
  }
  dap.configurations.rust = {
    {
      name = "Launch file",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    },
  }
  dap.configurations.c = dap.configurations.rust
  dap.configurations.cpp = dap.configurations.rust
end

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

map("n", "<leader>w", "<cmd>write<cr>", "Write buffer")
map("n", "<leader>q", "<cmd>quit<cr>", "Quit window")
map("n", "<leader>Q", "<cmd>qa<cr>", "Quit all")
map("n", "<leader>u", "<cmd>UndotreeToggle<cr>", "Undo tree")
map("n", "<leader>nh", "<cmd>nohlsearch<cr>", "Clear search highlight")

map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", "Toggle file tree")
map("n", "<leader>E", "<cmd>NvimTreeFindFile<cr>", "Reveal current file")

map("n", "<leader>bn", "<cmd>bnext<cr>", "Next buffer")
map("n", "<leader>bp", "<cmd>bprevious<cr>", "Previous buffer")
map("n", "<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")
map("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.bo[buf].buflisted then
      pcall(vim.api.nvim_buf_delete, buf, {})
    end
  end
end, "Close other buffers")
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", "Next buffer")
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", "Previous buffer")

map("n", "<leader>tn", "<cmd>tabnew<cr>", "New tab")
map("n", "<leader>tc", "<cmd>tabclose<cr>", "Close tab")
map("n", "<leader>to", "<cmd>tabonly<cr>", "Only tab")

map("n", "<C-h>", "<C-w>h", "Move left")
map("n", "<C-j>", "<C-w>j", "Move down")
map("n", "<C-k>", "<C-w>k", "Move up")
map("n", "<C-l>", "<C-w>l", "Move right")
map("n", "<A-h>", "<cmd>vertical resize -2<cr>", "Narrow window")
map("n", "<A-l>", "<cmd>vertical resize +2<cr>", "Widen window")
map("n", "<A-j>", "<cmd>resize -2<cr>", "Shorten window")
map("n", "<A-k>", "<cmd>resize +2<cr>", "Heighten window")

local function telescope_builtin(name)
  return function()
    local ok, builtin = pcall(require, "telescope.builtin")
    if ok then
      builtin[name]()
    else
      vim.notify("telescope.nvim is not available", vim.log.levels.WARN)
    end
  end
end

map("n", "<leader>ff", telescope_builtin("find_files"), "Find files")
map("n", "<leader>fg", telescope_builtin("live_grep"), "Live grep")
map("n", "<leader>fb", telescope_builtin("buffers"), "Find buffers")
map("n", "<leader>fh", telescope_builtin("help_tags"), "Help tags")
map("n", "<leader>fr", telescope_builtin("oldfiles"), "Recent files")
map("n", "<leader>/", telescope_builtin("current_buffer_fuzzy_find"), "Search current buffer")

map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", "Workspace diagnostics")
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Buffer diagnostics")
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", "Quickfix")

map("n", "<leader>lf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ async = true, lsp_format = "fallback" })
  else
    vim.lsp.buf.format({ async = true })
  end
end, "Format")

if ok_dap then
  map("n", "<leader>db", dap.toggle_breakpoint, "Toggle breakpoint")
  map("n", "<leader>dc", dap.continue, "Continue")
  map("n", "<leader>di", dap.step_into, "Step into")
  map("n", "<leader>do", dap.step_over, "Step over")
  map("n", "<leader>dO", dap.step_out, "Step out")
  map("n", "<leader>dr", dap.repl.open, "Open DAP REPL")
  map("n", "<leader>dt", dap.terminate, "Terminate debug")
  map("n", "<leader>du", function()
    local ok, dapui = pcall(require, "dapui")
    if ok then
      dapui.toggle()
    end
  end, "Toggle debug UI")
end

local function terminal_cmd(cmd)
  vim.cmd("botright 12split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end

local function shellescape_path(path)
  return vim.fn.shellescape(vim.fn.fnamemodify(path, ":p"))
end

vim.api.nvim_create_user_command("Run", function()
  local ft = vim.bo.filetype
  local file = shellescape_path(vim.api.nvim_buf_get_name(0))
  local commands = {
    rust = "cargo run",
    cs = "dotnet run",
    java = "mvn test",
    c = "make run",
    cpp = "make run",
    php = "php " .. file,
    html = "python3 -m http.server 8000",
    javascript = "node " .. file,
    typescript = "npx ts-node " .. file,
    python = "python3 " .. file,
    sh = "bash " .. file,
  }
  terminal_cmd(commands[ft] or "make")
end, { desc = "Run current project or file" })

vim.api.nvim_create_user_command("Test", function()
  local ft = vim.bo.filetype
  local commands = {
    rust = "cargo test",
    cs = "dotnet test",
    java = "mvn test",
    c = "make test",
    cpp = "make test",
    php = "vendor/bin/phpunit",
    javascript = "npm test",
    typescript = "npm test",
    python = "pytest",
  }
  terminal_cmd(commands[ft] or "make test")
end, { desc = "Run tests for current project" })

map("n", "<leader>rr", "<cmd>Run<cr>", "Run project/file")
map("n", "<leader>rt", "<cmd>Test<cr>", "Run tests")

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

local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

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
  pattern = { "help", "qf", "man", "checkhealth", "dap-float" },
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

vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
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
