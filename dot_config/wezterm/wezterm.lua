local wezterm    = require 'wezterm'
local config     = wezterm.config_builder()

-- ============================================================
-- 平台检测
-- ============================================================
local is_windows = wezterm.target_triple:find('windows') ~= nil
local is_linux   = wezterm.target_triple:find('linux') ~= nil
local is_darwin  = wezterm.target_triple:find('darwin') ~= nil

-- ============================================================
-- Shell 启动菜单
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

local function build_windows_shell_launch_menu()
    local function env_any(names)
        for _, name in ipairs(names) do
            local value = os.getenv(name)
            if value ~= nil and value ~= '' then
                return value
            end
        end

        return nil
    end

    local function clean_path(path)
        if path == nil then
            return nil
        end

        path = path:gsub('^"+', ''):gsub('"+$', '')
        path = path:gsub('/', '\\')
        return (path:gsub('\\+$', ''))
    end

    local function join_path(...)
        local parts = { ... }
        local result = clean_path(parts[1])

        if result == nil or result == '' then
            return nil
        end

        for i = 2, #parts do
            local part = clean_path(parts[i])
            if part ~= nil and part ~= '' then
                result = result .. '\\' .. part:gsub('^\\+', '')
            end
        end

        return result
    end

    local function lower_path(path)
        return string.lower(clean_path(path) or '')
    end

    local function append_dir(dirs, seen, path)
        path = clean_path(path)
        if path == nil or path == '' then
            return
        end

        local key = lower_path(path)
        if seen[key] == nil then
            table.insert(dirs, path)
            seen[key] = true
        end
    end

    local function split_path(value)
        local dirs = {}
        for dir in string.gmatch(value or '', '([^;]+)') do
            table.insert(dirs, dir)
        end

        return dirs
    end

    local function prefixed_dir(path)
        path = lower_path(path)
        if path == '' then
            return nil
        end

        return path .. '\\'
    end

    local profile = env_any { 'USERPROFILE' }
    if profile == nil then
        local home_drive = env_any { 'HOMEDRIVE' }
        local home_path = env_any { 'HOMEPATH' }
        if home_drive ~= nil and home_path ~= nil then
            profile = home_drive .. home_path
        end
    end

    local system_root = env_any { 'SystemRoot', 'WINDIR' } or 'C:\\Windows'
    local program_files = env_any { 'ProgramW6432', 'ProgramFiles' } or 'C:\\Program Files'
    local program_files_x86 = env_any { 'ProgramFiles(x86)' } or 'C:\\Program Files (x86)'
    local program_data = env_any { 'ProgramData' } or 'C:\\ProgramData'
    local local_app_data = env_any { 'LOCALAPPDATA' }
    local path_env = env_any { 'PATH', 'Path' }
    local cargo_home = env_any { 'CARGO_HOME' } or (profile and join_path(profile, '.cargo') or nil)

    local source_rules = {}
    local function add_source_rule(path, label)
        local prefix = prefixed_dir(path)
        if prefix ~= nil then
            table.insert(source_rules, { prefix = prefix, label = label })
        end
    end

    add_source_rule(cargo_home and join_path(cargo_home, 'bin') or nil, 'cargo')
    add_source_rule(profile and join_path(profile, 'scoop', 'shims') or nil, 'scoop')
    add_source_rule(program_data and join_path(program_data, 'scoop', 'shims') or nil, 'scoop')
    add_source_rule(program_data and join_path(program_data, 'chocolatey', 'bin') or nil, 'choco')
    add_source_rule(local_app_data and join_path(local_app_data, 'Microsoft', 'WindowsApps') or nil, 'store')

    local system_prefixes = {}
    for _, dir in ipairs {
        join_path(system_root, 'System32'),
        join_path(system_root, 'SysWOW64'),
        join_path(system_root, 'System32', 'WindowsPowerShell', 'v1.0'),
        join_path(program_files, 'PowerShell'),
        join_path(program_files_x86, 'PowerShell'),
    } do
        local prefix = prefixed_dir(dir)
        if prefix ~= nil then
            table.insert(system_prefixes, prefix)
        end
    end

    local function source_label(path)
        local normalized = lower_path(path)
        for _, rule in ipairs(source_rules) do
            if starts_with(normalized .. '\\', rule.prefix) or starts_with(normalized, rule.prefix) then
                return rule.label
            end
        end

        for _, prefix in ipairs(system_prefixes) do
            if starts_with(normalized .. '\\', prefix) or starts_with(normalized, prefix) then
                return nil
            end
        end

        if profile ~= nil and starts_with(normalized, lower_path(profile) .. '\\') then
            return 'user'
        end

        return nil
    end

    local path_dirs = {}
    local seen_path_dirs = {}
    for _, dir in ipairs(split_path(path_env)) do
        append_dir(path_dirs, seen_path_dirs, dir)
    end

    local candidate_dirs = {}
    local seen_candidate_dirs = {}
    append_dir(candidate_dirs, seen_candidate_dirs, join_path(system_root, 'System32'))
    append_dir(candidate_dirs, seen_candidate_dirs, join_path(system_root, 'System32', 'WindowsPowerShell', 'v1.0'))
    append_dir(candidate_dirs, seen_candidate_dirs, join_path(program_files, 'PowerShell', '7'))
    append_dir(candidate_dirs, seen_candidate_dirs, join_path(program_files, 'PowerShell', '7-preview'))
    append_dir(candidate_dirs, seen_candidate_dirs, join_path(program_files_x86, 'PowerShell', '7'))
    append_dir(candidate_dirs, seen_candidate_dirs, local_app_data and join_path(local_app_data, 'Microsoft', 'WindowsApps') or nil)
    append_dir(candidate_dirs, seen_candidate_dirs, cargo_home and join_path(cargo_home, 'bin') or nil)
    append_dir(candidate_dirs, seen_candidate_dirs, profile and join_path(profile, 'scoop', 'shims') or nil)
    append_dir(candidate_dirs, seen_candidate_dirs, program_data and join_path(program_data, 'scoop', 'shims') or nil)
    append_dir(candidate_dirs, seen_candidate_dirs, program_data and join_path(program_data, 'chocolatey', 'bin') or nil)
    append_dir(candidate_dirs, seen_candidate_dirs, join_path(program_files, 'Git', 'bin'))
    append_dir(candidate_dirs, seen_candidate_dirs, join_path(program_files, 'Git', 'usr', 'bin'))
    append_dir(candidate_dirs, seen_candidate_dirs, join_path(program_files_x86, 'Git', 'bin'))
    append_dir(candidate_dirs, seen_candidate_dirs, join_path(program_files_x86, 'Git', 'usr', 'bin'))
    append_dir(candidate_dirs, seen_candidate_dirs, local_app_data and join_path(local_app_data, 'Programs', 'Git', 'bin') or nil)
    append_dir(candidate_dirs, seen_candidate_dirs, local_app_data and join_path(local_app_data, 'Programs', 'Git', 'usr', 'bin') or nil)
    append_dir(candidate_dirs, seen_candidate_dirs, 'C:\\msys64\\usr\\bin')
    append_dir(candidate_dirs, seen_candidate_dirs, 'C:\\msys32\\usr\\bin')
    append_dir(candidate_dirs, seen_candidate_dirs, 'C:\\cygwin64\\bin')
    append_dir(candidate_dirs, seen_candidate_dirs, 'C:\\cygwin\\bin')

    for _, dir in ipairs(path_dirs) do
        append_dir(candidate_dirs, seen_candidate_dirs, dir)
    end

    local function collect_exe_paths(exe)
        local paths = {}
        local seen_paths = {}
        for _, dir in ipairs(candidate_dirs) do
            local path = join_path(dir, exe)
            local key = lower_path(path)
            if seen_paths[key] == nil and file_exists(path) then
                table.insert(paths, path)
                seen_paths[key] = true
            end
        end

        return paths
    end

    local path_dir_lookup = {}
    for _, dir in ipairs(path_dirs) do
        path_dir_lookup[lower_path(dir)] = true
    end

    local function command_arg(path, exe)
        local dir = path:match('^(.*)\\[^\\]+$')
        if dir ~= nil and path_dir_lookup[lower_path(dir)] then
            return exe
        end

        return path
    end

    local launch_menu = {}
    local seen_entries = {}
    local function add_item(label, args, identity)
        identity = lower_path(identity or args[1])
        if seen_entries[identity] ~= nil then
            return
        end

        table.insert(launch_menu, {
            label = label,
            args = args,
        })
        seen_entries[identity] = true
    end

    local function add_first(label, exe, extra_args)
        local paths = collect_exe_paths(exe)
        if #paths == 0 then
            return
        end

        local args = { command_arg(paths[1], exe) }
        for _, arg in ipairs(extra_args or {}) do
            table.insert(args, arg)
        end
        add_item(label, args, label)
    end

    add_first('PowerShell Core', 'pwsh.exe', { '-NoExit', '-NoLogo' })
    add_first('PowerShell', 'powershell.exe', { '-NoExit', '-NoLogo' })
    add_first('Command Prompt', 'cmd.exe')

    local nu_paths = collect_exe_paths('nu.exe')
    for _, path in ipairs(nu_paths) do
        if source_label(path) == nil then
            add_item('Nushell', { command_arg(path, 'nu.exe') }, path)
            break
        end
    end
    for _, path in ipairs(nu_paths) do
        local source = source_label(path)
        if source ~= nil then
            add_item('Nushell (' .. source .. ')', { path }, path)
        end
    end

    local bash_paths = collect_exe_paths('bash.exe')
    local function add_bash(label, paths, fragments)
        for _, path in ipairs(paths) do
            path = clean_path(path)
            if file_exists(path) then
                add_item(label, { path, '-i', '-l' }, label)
                return
            end
        end

        for _, path in ipairs(bash_paths) do
            local normalized = lower_path(path)
            for _, fragment in ipairs(fragments or {}) do
                if normalized:find(fragment, 1, true) then
                    add_item(label, { path, '-i', '-l' }, label)
                    return
                end
            end
        end
    end

    add_bash('Git Bash', {
        join_path(program_files, 'Git', 'bin', 'bash.exe'),
        join_path(program_files, 'Git', 'usr', 'bin', 'bash.exe'),
        join_path(program_files_x86, 'Git', 'bin', 'bash.exe'),
        join_path(program_files_x86, 'Git', 'usr', 'bin', 'bash.exe'),
        local_app_data and join_path(local_app_data, 'Programs', 'Git', 'bin', 'bash.exe') or nil,
        local_app_data and join_path(local_app_data, 'Programs', 'Git', 'usr', 'bin', 'bash.exe') or nil,
    }, {
        '\\git\\bin\\bash.exe',
        '\\git\\usr\\bin\\bash.exe',
    })

    add_bash('MSYS2 Bash', {
        'C:\\msys64\\usr\\bin\\bash.exe',
        'C:\\msys32\\usr\\bin\\bash.exe',
    }, {
        '\\msys64\\usr\\bin\\bash.exe',
        '\\msys32\\usr\\bin\\bash.exe',
        '\\msys2\\usr\\bin\\bash.exe',
    })

    add_bash('Cygwin Bash', {
        'C:\\cygwin64\\bin\\bash.exe',
        'C:\\cygwin\\bin\\bash.exe',
    }, {
        '\\cygwin64\\bin\\bash.exe',
        '\\cygwin\\bin\\bash.exe',
    })

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

if is_windows then
    config.launch_menu = build_windows_shell_launch_menu()
else
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
