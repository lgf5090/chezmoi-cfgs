local wezterm    = require 'wezterm'
local config     = wezterm.config_builder()

-- ============================================================
-- 平台检测
-- ============================================================
local is_windows = wezterm.target_triple == 'x86_64-pc-windows-msvc'
local is_linux   = wezterm.target_triple:find('linux') ~= nil
local is_darwin  = wezterm.target_triple:find('darwin') ~= nil

-- ============================================================
-- Unix Shell 启动菜单
-- ============================================================
local function starts_with(value, prefix)
    return value:sub(1, #prefix) == prefix
end

local function trim(value)
    return (value:gsub('%s+$', ''))
end

local function run_child_process(argv)
    if wezterm.run_child_process == nil then
        return false, ''
    end

    local ok, success, stdout = pcall(wezterm.run_child_process, argv)
    if not ok then
        return false, ''
    end

    return success, stdout or ''
end

local function file_exists(path)
    local file = io.open(path, 'r')
    if file ~= nil then
        file:close()
        return true
    end

    return false
end

local function is_executable(path)
    if not file_exists(path) then
        return false
    end

    if wezterm.run_child_process ~= nil then
        local success = run_child_process { 'test', '-x', path }
        return success
    end

    return true
end

local function build_unix_shell_launch_menu()
    local home = os.getenv 'HOME'

    local function expand_home(path)
        if home ~= nil and starts_with(path, '~/') then
            return home .. path:sub(2)
        end

        return path
    end

    local function normalize_dir(path)
        path = expand_home(path)
        return (path:gsub('/+$', ''))
    end

    local function append_dir(dirs, seen, path)
        if path == nil or path == '' then
            return
        end

        path = normalize_dir(path)
        if path ~= '' and seen[path] == nil then
            table.insert(dirs, path)
            seen[path] = true
        end
    end

    local function append_env_prefix_bin(dirs, seen, env_name)
        local prefix = os.getenv(env_name)
        if prefix ~= nil and prefix ~= '' then
            append_dir(dirs, seen, prefix .. '/bin')
        end
    end

    local function split_path(value)
        local dirs = {}
        for dir in string.gmatch(value or '', '([^:]+)') do
            table.insert(dirs, dir)
        end

        return dirs
    end

    local function prefixed_dir(path)
        path = normalize_dir(path)
        return path .. '/'
    end

    local source_rules = {}

    local function add_source_rule(path, label)
        if path ~= nil and path ~= '' then
            table.insert(source_rules, { prefix = prefixed_dir(path), label = label })
        end
    end

    add_source_rule(os.getenv 'HOMEBREW_PREFIX', 'brew')
    add_source_rule(os.getenv 'LINUXBREW_PREFIX', 'brew')
    add_source_rule('/home/linuxbrew/.linuxbrew', 'brew')
    add_source_rule('/opt/homebrew', 'brew')
    add_source_rule('/usr/local/Homebrew', 'brew')
    add_source_rule('/usr/local/Cellar', 'brew')
    add_source_rule('/usr/local/opt', 'brew')

    local cargo_home = os.getenv 'CARGO_HOME'
    if cargo_home == nil or cargo_home == '' then
        cargo_home = home and (home .. '/.cargo') or nil
    end
    add_source_rule(cargo_home and (cargo_home .. '/bin') or nil, 'cargo')

    add_source_rule(os.getenv 'ASDF_DATA_DIR', 'asdf')
    add_source_rule('~/.asdf/shims', 'asdf')
    add_source_rule(os.getenv 'MISE_DATA_DIR', 'mise')
    add_source_rule('~/.local/share/mise/shims', 'mise')
    add_source_rule('~/.mise/shims', 'mise')
    add_source_rule('~/.nix-profile/bin', 'nix')
    add_source_rule('/nix/store', 'nix')
    add_source_rule('/run/current-system/sw/bin', 'nix')
    add_source_rule('/nix/var/nix/profiles/default/bin', 'nix')
    add_source_rule('/snap/bin', 'snap')
    add_source_rule('/var/lib/snapd/snap/bin', 'snap')
    add_source_rule('~/.local/bin', 'local')
    add_source_rule('~/bin', 'local')
    add_source_rule(os.getenv 'CONDA_PREFIX', 'conda')

    local system_prefixes = {}
    for _, dir in ipairs {
        '/bin',
        '/sbin',
        '/usr/bin',
        '/usr/sbin',
        '/usr/local/bin',
        '/usr/local/sbin',
    } do
        table.insert(system_prefixes, prefixed_dir(dir))
    end

    local realpaths = {}
    local function realpath(path)
        if realpaths[path] ~= nil then
            return realpaths[path]
        end

        local success, stdout = run_child_process { 'realpath', path }
        if success and stdout ~= '' then
            realpaths[path] = trim(stdout)
        else
            realpaths[path] = path
        end

        return realpaths[path]
    end

    local function source_label(path)
        local resolved = realpath(path)

        for _, rule in ipairs(source_rules) do
            if starts_with(path, rule.prefix) or starts_with(resolved, rule.prefix) then
                return rule.label
            end
        end

        for _, prefix in ipairs(system_prefixes) do
            if starts_with(path, prefix) or starts_with(resolved, prefix) then
                return nil
            end
        end

        if home ~= nil and starts_with(path, home .. '/') then
            return 'user'
        end

        if starts_with(path, '/opt/') then
            return 'opt'
        end

        return 'custom'
    end

    local candidate_dirs = {}
    local seen_dirs = {}
    for _, dir in ipairs {
        '/bin',
        '/usr/bin',
        '/usr/local/bin',
        '/sbin',
        '/usr/sbin',
        '/usr/local/sbin',
        '/home/linuxbrew/.linuxbrew/bin',
        '/opt/homebrew/bin',
        '~/.cargo/bin',
        '~/.local/bin',
        '~/bin',
        '~/.nix-profile/bin',
        '/run/current-system/sw/bin',
        '/nix/var/nix/profiles/default/bin',
        '/snap/bin',
        '/var/lib/snapd/snap/bin',
        '~/.asdf/shims',
        '~/.local/share/mise/shims',
        '~/.mise/shims',
    } do
        append_dir(candidate_dirs, seen_dirs, dir)
    end

    append_env_prefix_bin(candidate_dirs, seen_dirs, 'HOMEBREW_PREFIX')
    append_env_prefix_bin(candidate_dirs, seen_dirs, 'LINUXBREW_PREFIX')
    append_env_prefix_bin(candidate_dirs, seen_dirs, 'CONDA_PREFIX')

    if cargo_home ~= nil then
        append_dir(candidate_dirs, seen_dirs, cargo_home .. '/bin')
    end

    for _, dir in ipairs(split_path(os.getenv 'PATH')) do
        append_dir(candidate_dirs, seen_dirs, dir)
    end

    local shells = {
        { exe = 'bash', label = 'Bash' },
        { exe = 'zsh',  label = 'Zsh' },
        { exe = 'ksh',  label = 'Ksh' },
        { exe = 'ksh93', label = 'Ksh93' },
        { exe = 'mksh', label = 'Mksh' },
        { exe = 'csh',  label = 'Csh' },
        { exe = 'tcsh', label = 'Tcsh' },
        { exe = 'fish', label = 'Fish' },
        { exe = 'nu',   label = 'NuShell' },
        { exe = 'pwsh', label = 'PowerShell' },
        { exe = 'sh',   label = 'Sh' },
        { exe = 'dash', label = 'Dash' },
        { exe = 'ash',  label = 'Ash' },
        { exe = 'yash', label = 'Yash' },
        { exe = 'elvish', label = 'Elvish' },
        { exe = 'xonsh', label = 'Xonsh' },
    }

    local launch_menu = {}
    local seen_labels = {}
    for _, shell in ipairs(shells) do
        for _, dir in ipairs(candidate_dirs) do
            local path = dir .. '/' .. shell.exe
            if is_executable(path) then
                local label = shell.label
                local source = source_label(path)
                if source ~= nil then
                    label = label .. '(' .. source .. ')'
                end

                if seen_labels[label] == nil then
                    table.insert(launch_menu, {
                        label = label,
                        args = { path },
                    })
                    seen_labels[label] = true
                end
            end
        end
    end

    return launch_menu
end

-- ============================================================
-- 外观
-- ============================================================
config.color_scheme                                = 'Catppuccin Mocha'

config.font                                        = wezterm.font_with_fallback {
    'Hack Nerd Font',
    'JetBrains Mono',
    'DejaVu Sans Mono',
    'Courier New',
}
config.font_size                                   = 12.0

-- 光标：闪烁竖线，匀速闪烁
config.default_cursor_style                        = 'BlinkingBar'
config.cursor_blink_rate                           = 500 -- ms
config.cursor_blink_ease_in                        = 'Constant'
config.cursor_blink_ease_out                       = 'Constant'

-- 关闭响铃
config.audible_bell                                = 'Disabled'

-- ============================================================
-- 窗口
-- ============================================================
config.window_decorations                          = 'NONE'
config.window_background_opacity                   = 0.95
config.window_padding                              = { left = 10, right = 10, top = 10, bottom = 10 }
config.initial_cols                                = 120
config.initial_rows                                = 30
config.scrollback_lines                            = 10000 -- 滚动缓冲区行数
config.window_close_confirmation                   = 'NeverPrompt'
config.exit_behavior                               = 'Close'
config.exit_behavior_messaging                     = 'None'

-- ============================================================
-- 标签页
-- ============================================================
config.use_fancy_tab_bar                           = true
config.tab_bar_at_bottom                           = false
config.hide_tab_bar_if_only_one_tab                = false

if not is_windows then
    config.launch_menu = build_unix_shell_launch_menu()
end

-- ============================================================
-- 快捷键
-- ============================================================
local act = wezterm.action

config.keys = {
    -- 全屏切换
    { key = 'f',     mods = 'ALT',        action = act.ToggleFullScreen },

    -- 标签页
    { key = 't',     mods = 'ALT',        action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'w',     mods = 'ALT',        action = act.CloseCurrentPane { confirm = false } },
    { key = '[',     mods = 'ALT',        action = act.ActivateTabRelative(-1) },
    { key = ']',     mods = 'ALT',        action = act.ActivateTabRelative(1) },
    -- 标签页直跳 ALT+1~9
    { key = '1',     mods = 'ALT',        action = act.ActivateTab(0) },
    { key = '2',     mods = 'ALT',        action = act.ActivateTab(1) },
    { key = '3',     mods = 'ALT',        action = act.ActivateTab(2) },
    { key = '4',     mods = 'ALT',        action = act.ActivateTab(3) },
    { key = '5',     mods = 'ALT',        action = act.ActivateTab(4) },
    { key = '6',     mods = 'ALT',        action = act.ActivateTab(5) },
    { key = '7',     mods = 'ALT',        action = act.ActivateTab(6) },
    { key = '8',     mods = 'ALT',        action = act.ActivateTab(7) },
    { key = '9',     mods = 'ALT',        action = act.ActivateTab(8) },

    -- 面板分割
    { key = '\\',    mods = 'ALT',        action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'Enter', mods = 'ALT',        action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

    -- 面板导航 ALT+HJKL（Vim 风格）
    { key = 'h',     mods = 'ALT',        action = act.ActivatePaneDirection 'Left' },
    { key = 'l',     mods = 'ALT',        action = act.ActivatePaneDirection 'Right' },
    { key = 'k',     mods = 'ALT',        action = act.ActivatePaneDirection 'Up' },
    { key = 'j',     mods = 'ALT',        action = act.ActivatePaneDirection 'Down' },

    -- 字体大小
    { key = '=',     mods = 'CTRL',       action = act.IncreaseFontSize },
    { key = '-',     mods = 'CTRL',       action = act.DecreaseFontSize },
    { key = '0',     mods = 'CTRL',       action = act.ResetFontSize },

    -- 复制 / 粘贴
    { key = 'c',     mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
    { key = 'v',     mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },

    -- 退出应用
    { key = 'q',     mods = 'ALT',        action = act.QuitApplication },
    { key = 'q',     mods = 'CTRL|SHIFT', action = act.QuitApplication },
}

return config
