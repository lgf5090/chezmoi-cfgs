--------------------------------------------------------------------------------
-- Shells prompt for Clink.
--
-- This is the Clink/cmd equivalent of the PowerShell fallback prompt.  It reads
-- git metadata directly from .git/HEAD and never runs git.exe.

local S = shells
if not S or not clink or type(clink.promptfilter) ~= "function" then
    return
end

local esc = "\27"
local use_ansi = S.is_blank(S.env("NO_COLOR"))
local color = {
    reset = use_ansi and esc .. "[0m" or "",
    gray = use_ansi and esc .. "[90m" or "",
    white = use_ansi and esc .. "[97m" or "",
    red = use_ansi and esc .. "[31m" or "",
    green = use_ansi and esc .. "[32m" or "",
    blue = use_ansi and esc .. "[34m" or "",
    magenta = use_ansi and esc .. "[35m" or "",
    cyan = use_ansi and esc .. "[36m" or "",
}

local function parent_dir(value)
    if S.is_blank(value) then
        return nil
    end
    local p = tostring(value):gsub("[\\/]+$", "")
    local parent = p:match("^(.*)[\\/][^\\/]+$")
    if S.is_blank(parent) or parent == p then
        return nil
    end
    return parent
end

local function is_root(value)
    if S.is_blank(value) then
        return true
    end
    local p = tostring(value):gsub("[\\/]+$", "")
    return p:match("^%a:$") ~= nil or p == "\\\\" or p == ""
end

local function rooted(value)
    return tostring(value or ""):match("^%a:[\\/]") ~= nil or tostring(value or ""):match("^\\\\") ~= nil
end

local function first_line(file)
    local lines = S.read_lines(file)
    if #lines == 0 then
        return nil
    end
    return S.trim(lines[1])
end

local function find_git_dir(start)
    local dir = start
    while not S.is_blank(dir) do
        local dotgit = S.join_path(dir, ".git")
        if S.is_dir(dotgit) then
            return S.full_path(dotgit)
        end

        if S.is_file(dotgit) then
            local line = first_line(dotgit)
            local gitdir = line and line:match("^gitdir:%s*(.+)$")
            if not S.is_blank(gitdir) then
                gitdir = S.trim(gitdir)
                if not rooted(gitdir) then
                    gitdir = S.join_path(dir, gitdir)
                end
                if S.is_dir(gitdir) then
                    return S.full_path(gitdir)
                end
            end
        end

        if is_root(dir) then
            break
        end
        dir = parent_dir(dir)
    end
    return nil
end

local function git_branch(cwd)
    local gitdir = find_git_dir(cwd)
    if S.is_blank(gitdir) then
        return nil
    end

    local head = first_line(S.join_path(gitdir, "HEAD"))
    if S.is_blank(head) then
        return nil
    end

    local branch = head:match("^ref:%s*refs/heads/(.+)$")
    if not S.is_blank(branch) then
        return branch
    end

    local ref = head:match("^ref:%s*(.+)$")
    if not S.is_blank(ref) then
        return ref
    end

    if #head > 7 then
        return head:sub(1, 7)
    end
    return head
end

local function display_cwd(cwd)
    local home = S.home_dir()
    if not S.is_blank(home) and S.starts_with_ci(cwd, home) then
        return "~" .. cwd:sub(#home + 1)
    end
    return cwd
end

local function env_name(path_value)
    if S.is_blank(path_value) then
        return nil
    end
    local normalized = tostring(path_value):gsub("[\\/]+$", "")
    return normalized:match("[^\\/]+$") or normalized
end

local pf = clink.promptfilter(30)

function pf:filter(_)
    local cwd = os.getcwd()
    local extras = {}

    local venv = env_name(S.env("VIRTUAL_ENV"))
    if not S.is_blank(venv) then
        extras[#extras + 1] = color.cyan .. "(" .. venv .. ")" .. color.reset
    elseif not S.is_blank(S.env("CONDA_DEFAULT_ENV")) and S.env("CONDA_DEFAULT_ENV") ~= "base" then
        extras[#extras + 1] = color.cyan .. S.env("CONDA_DEFAULT_ENV") .. color.reset
    end

    local branch = git_branch(cwd)
    if not S.is_blank(branch) then
        extras[#extras + 1] = color.magenta .. branch .. color.reset
    end

    local rc = tonumber(S.safe_call(os.geterrorlevel) or 0) or 0
    local rc_text = ""
    if rc ~= 0 then
        rc_text = " " .. color.red .. "[" .. tostring(rc) .. "]" .. color.reset
    end

    local extra_text = ""
    if #extras > 0 then
        extra_text = " " .. table.concat(extras, " ")
    end

    local user = S.env("USERNAME") or "user"
    local host = S.env("COMPUTERNAME") or "host"
    local time = os.date("%H:%M:%S")

    return color.gray .. "[" .. time .. "]" .. color.reset .. " " ..
        color.green .. user .. color.white .. "@" .. host .. color.reset .. " " ..
        color.blue .. "[" .. display_cwd(cwd) .. "]" .. color.reset ..
        extra_text .. rc_text .. "\n" ..
        color.cyan .. "CMD>" .. color.reset .. " ", false
end

