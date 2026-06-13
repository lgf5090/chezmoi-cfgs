--------------------------------------------------------------------------------
-- Environment and PATH setup for Clink/cmd.
--
-- Only Clink Lua APIs and Lua built-ins are used.  Tool managers are exposed by
-- environment variables and PATH entries, but their init hooks are not executed.

local S = shells
if not S then
    return
end

local home = S.home_dir()
local localappdata = S.env("LOCALAPPDATA")
local appdata = S.env("APPDATA")
local programdata = S.env("PROGRAMDATA")
local programfiles = S.env("ProgramFiles")
local programfiles_x86 = S.env("ProgramFiles(x86)")

S.set_env("SHELLS_OS", "windows")
S.set_env("SHELLS_CLINK", "1")

S.set_env_if_empty("XDG_CONFIG_HOME", S.join_path(home, ".config"))
S.set_env_if_empty("XDG_DATA_HOME", S.join_path(home, ".local", "share"))
S.set_env_if_empty("XDG_STATE_HOME", S.join_path(home, ".local", "state"))
S.set_env_if_empty("XDG_CACHE_HOME", S.join_path(home, ".cache"))

S.set_env_if_empty("EDITOR", "notepad.exe")
S.set_env_if_empty("VISUAL", S.env("EDITOR"))
S.set_env_if_empty("CLICOLOR", "1")

local function load_local_envs()
    local file = S.env("CLINK_LOCAL_ENVS_FILE")
    if S.is_blank(file) then
        file = S.env("POWERSHELL_LOCAL_ENVS_FILE")
    end
    if S.is_blank(file) then
        file = S.join_path(home, ".envs")
    end

    for _, raw in ipairs(S.read_lines(file)) do
        local line = raw:match("^%s*(.*)$") or ""
        if line ~= "" and line:sub(1, 1) ~= "#" then
            if S.starts_with_ci(line, "export ") then
                line = S.trim(line:sub(8))
            end

            local eq = line:find("=", 1, true)
            if eq and eq > 1 then
                local key = S.trim(line:sub(1, eq - 1))
                local value = S.strip_outer_quotes(line:sub(eq + 1))
                if key:match("^[A-Za-z_][A-Za-z0-9_]*$") then
                    value = value:gsub("{HOME}", home)
                    value = value:gsub("{PATH}", S.env("PATH") or "")
                    if key:upper() == "PATH" then
                        S.add_path_prepend_value(value)
                    else
                        S.set_env(key, value)
                    end
                end
            end
        end
    end
end

local function latest_child_dir(root, filter)
    if S.is_blank(root) or not S.is_dir(root) then
        return nil
    end

    local pattern = S.join_path(root, filter or "*")
    local items = S.safe_call(os.globdirs, pattern) or {}
    if #items == 0 then
        return nil
    end

    table.sort(items, function(a, b)
        return tostring(a):lower() > tostring(b):lower()
    end)

    local item = tostring(items[1]):gsub("[\\/]$", "")
    if item:match("^%a:[\\/]") or item:match("^\\\\") then
        return S.full_path(item)
    end
    return S.full_path(S.join_path(root, item))
end

local function setup_toolchain_env()
    local xdg_data_home = S.env("XDG_DATA_HOME")

    S.set_env_if_empty("NPM_CONFIG_PREFIX", S.join_path(home, ".npm-global"))
    S.set_env_if_empty("PNPM_HOME", S.join_path(home, ".pnpm-global"))
    S.set_env_if_empty("MISE_DATA_DIR", S.join_path(xdg_data_home, "mise"))
    S.set_env_if_empty("GOPATH", S.join_path(home, "go"))
    S.set_env_if_empty("NVM_DIR", S.join_path(home, ".nvm"))
    S.set_env_if_empty("SDKMAN_DIR", S.join_path(home, ".sdkman"))
    S.set_env_if_empty("DOCKER_BUILDKIT", "1")
    S.set_env_if_empty("COMPOSE_DOCKER_CLI_BUILD", "1")

    S.set_env_first_existing_dir("FNM_DIR", {
        S.join_path(xdg_data_home, "fnm"),
        S.join_path(home, ".fnm"),
    })
    S.set_env_first_existing_dir("VOLTA_HOME", {
        S.join_path(home, ".volta"),
    })
    S.set_env_first_existing_dir("BUN_INSTALL", {
        S.join_path(home, ".bun"),
    })
    S.set_env_first_existing_dir("DENO_INSTALL", {
        S.join_path(home, ".deno"),
    })
    S.set_env_first_existing_dir("GOROOT", {
        S.join_path(home, ".local", "go"),
        localappdata and S.join_path(localappdata, "Programs", "Go") or nil,
        programfiles and S.join_path(programfiles, "Go") or nil,
        programfiles_x86 and S.join_path(programfiles_x86, "Go") or nil,
        "C:\\Go",
    })
    S.set_env_first_existing_dir("ANACONDA_HOME", {
        S.join_path(home, "anaconda3"),
        S.join_path(home, "miniconda3"),
        localappdata and S.join_path(localappdata, "anaconda3") or nil,
        localappdata and S.join_path(localappdata, "miniconda3") or nil,
        programdata and S.join_path(programdata, "anaconda3") or nil,
        programdata and S.join_path(programdata, "miniconda3") or nil,
    })
    S.set_env_first_existing_dir("POETRY_HOME", {
        S.join_path(home, ".poetry"),
    })
    S.set_env_first_existing_dir("PYENV_ROOT", {
        S.join_path(home, ".pyenv", "pyenv-win"),
        S.join_path(home, ".pyenv"),
    })
    S.set_env_first_existing_dir("ASDF_DIR", {
        S.join_path(home, ".asdf"),
    })

    if S.is_blank(S.env("ASDF_DATA_DIR")) and not S.is_blank(S.env("ASDF_DIR")) then
        if S.env("ASDF_DIR"):lower() == S.join_path(home, ".asdf"):lower() then
            S.set_env("ASDF_DATA_DIR", S.env("ASDF_DIR"))
        else
            S.set_env("ASDF_DATA_DIR", S.join_path(xdg_data_home, "asdf"))
        end
    end

    S.set_env_first_existing_dir("RBENV_ROOT", { S.join_path(home, ".rbenv") })
    S.set_env_first_existing_dir("NODENV_ROOT", { S.join_path(home, ".nodenv") })
    S.set_env_first_existing_dir("GOENV_ROOT", { S.join_path(home, ".goenv") })
    S.set_env_first_existing_dir("JENV_ROOT", { S.join_path(home, ".jenv") })

    S.set_env_first_existing_dir("NVM_HOME", {
        appdata and S.join_path(appdata, "nvm") or nil,
        S.join_path(home, "scoop", "apps", "nvm", "current"),
        S.join_path(home, ".nvm"),
    })
    S.set_env_first_existing_dir("NVM_SYMLINK", {
        programfiles and S.join_path(programfiles, "nodejs") or nil,
        S.join_path(home, "scoop", "apps", "nodejs", "current"),
    })

    if S.is_blank(S.env("JAVA_HOME")) then
        local roots = {
            programfiles and S.join_path(programfiles, "Java") or nil,
            programfiles and S.join_path(programfiles, "Eclipse Adoptium") or nil,
            programfiles and S.join_path(programfiles, "Microsoft") or nil,
            programfiles and S.join_path(programfiles, "Zulu") or nil,
        }
        S.each(roots, function(root)
            if not S.is_blank(S.env("JAVA_HOME")) then
                return
            end
            local candidate = latest_child_dir(root, "jdk*")
            if not S.is_blank(candidate) and S.is_dir(candidate) then
                S.set_env("JAVA_HOME", candidate)
            end
        end)
    end

    local lf_icons = S.join_path(S.env("XDG_CONFIG_HOME"), "lf", "icons")
    if S.is_file(lf_icons) then
        local lines = S.read_lines(lf_icons)
        if #lines > 0 then
            S.set_env("LF_ICONS", table.concat(lines, ":") .. ":")
        end
    end
end

local function setup_path()
    local cargo_home = S.env("CARGO_HOME")
    if S.is_blank(cargo_home) then
        cargo_home = S.join_path(home, ".cargo")
    end

    local append = {
        S.join_path(home, ".lmstudio", "bin"),
        S.join_path(home, ".mimocode", "bin"),
        S.join_path(home, ".local", "bin"),
        S.join_path(home, "bin"),
        S.join_path(home, "Applications"),
        S.join_path(home, ".local", "Applications"),
    }

    local prepend = {
        S.env("ASDF_DIR") and S.join_path(S.env("ASDF_DIR"), "bin") or nil,
        S.env("RBENV_ROOT") and S.join_path(S.env("RBENV_ROOT"), "bin") or nil,
        S.env("NODENV_ROOT") and S.join_path(S.env("NODENV_ROOT"), "bin") or nil,
        S.env("GOENV_ROOT") and S.join_path(S.env("GOENV_ROOT"), "bin") or nil,
        S.env("JENV_ROOT") and S.join_path(S.env("JENV_ROOT"), "bin") or nil,
        S.join_path(cargo_home, "bin"),
        S.join_path(home, ".rd", "bin"),
        S.join_path(home, ".opencode", "bin"),
        S.env("BUN_INSTALL") and S.join_path(S.env("BUN_INSTALL"), "bin") or nil,
        S.env("DENO_INSTALL") and S.join_path(S.env("DENO_INSTALL"), "bin") or nil,
        S.env("NPM_CONFIG_PREFIX") and S.join_path(S.env("NPM_CONFIG_PREFIX"), "bin") or nil,
        S.env("PNPM_HOME"),
        S.join_path(home, ".yarn", "bin"),
        S.join_path(home, ".config", "yarn", "global", "node_modules", ".bin"),
        S.env("VOLTA_HOME") and S.join_path(S.env("VOLTA_HOME"), "bin") or nil,
        S.join_path(home, ".volta", "bin"),
        S.env("FNM_DIR"),
        S.join_path(home, ".local", "share", "npm", "bin"),
        S.env("PYENV_ROOT") and S.join_path(S.env("PYENV_ROOT"), "bin") or nil,
        S.env("ANACONDA_HOME") and S.join_path(S.env("ANACONDA_HOME"), "bin") or nil,
        S.env("ANACONDA_HOME") and S.join_path(S.env("ANACONDA_HOME"), "Scripts") or nil,
        S.env("ANACONDA_HOME") and S.join_path(S.env("ANACONDA_HOME"), "condabin") or nil,
        S.env("POETRY_HOME") and S.join_path(S.env("POETRY_HOME"), "bin") or nil,
        S.join_path(home, ".poetry", "bin"),
        S.join_path(home, ".local", "pipx", "bin"),
        S.env("GOPATH") and S.join_path(S.env("GOPATH"), "bin") or nil,
        S.env("GOROOT") and S.join_path(S.env("GOROOT"), "bin") or nil,
        S.join_path(home, ".local", "bin"),
        S.join_path(home, "bin"),
        S.join_path(home, "scoop", "shims"),
        programdata and S.join_path(programdata, "scoop", "shims") or nil,
        programdata and S.join_path(programdata, "chocolatey", "bin") or nil,
        localappdata and S.join_path(localappdata, "Microsoft", "WindowsApps") or nil,
        appdata and S.join_path(appdata, "npm") or nil,
        S.join_path(home, ".nix-profile", "bin"),
        S.join_path(home, ".mise", "shims"),
        S.env("MISE_DATA_DIR") and S.join_path(S.env("MISE_DATA_DIR"), "shims") or nil,
        S.env("ASDF_DATA_DIR") and S.join_path(S.env("ASDF_DATA_DIR"), "shims") or nil,
        S.env("PYENV_ROOT") and S.join_path(S.env("PYENV_ROOT"), "shims") or nil,
        S.env("PYENV_ROOT") and S.join_path(S.env("PYENV_ROOT"), "pyenv-win", "bin") or nil,
        S.env("PYENV_ROOT") and S.join_path(S.env("PYENV_ROOT"), "pyenv-win", "shims") or nil,
        S.env("FNM_DIR") and S.join_path(S.env("FNM_DIR"), "aliases", "default", "bin") or nil,
        S.env("NVM_HOME"),
        S.env("NVM_SYMLINK"),
        S.env("JAVA_HOME") and S.join_path(S.env("JAVA_HOME"), "bin") or nil,
        S.env("RBENV_ROOT") and S.join_path(S.env("RBENV_ROOT"), "shims") or nil,
        S.env("NODENV_ROOT") and S.join_path(S.env("NODENV_ROOT"), "shims") or nil,
        S.env("GOENV_ROOT") and S.join_path(S.env("GOENV_ROOT"), "shims") or nil,
        S.env("JENV_ROOT") and S.join_path(S.env("JENV_ROOT"), "shims") or nil,
    }

    S.add_path_append(append)
    S.add_path_prepend(prepend)
end

load_local_envs()
setup_toolchain_env()
setup_path()
