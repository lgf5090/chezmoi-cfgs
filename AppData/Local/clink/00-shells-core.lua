--------------------------------------------------------------------------------
-- Shells core helpers for Clink.
--
-- This file intentionally uses only Clink's Lua APIs and Lua built-ins.  It does
-- not run external programs.

shells = shells or {}
shells.version = 1

local M = shells

local function safe_call(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end

    local ok, a, b, c = pcall(fn, ...)
    if ok then
        return a, b, c
    end
    return nil
end

M.safe_call = safe_call

function M.is_blank(value)
    return value == nil or tostring(value):match("^%s*$") ~= nil
end

function M.trim(value)
    if value == nil then
        return ""
    end
    return tostring(value):match("^%s*(.-)%s*$")
end

function M.strip_outer_quotes(value)
    value = M.trim(value)
    if #value >= 2 then
        local first = value:sub(1, 1)
        local last = value:sub(-1)
        if (first == '"' and last == '"') or (first == "'" and last == "'") then
            return value:sub(2, -2)
        end
    end
    return value
end

function M.starts_with_ci(value, prefix)
    if value == nil or prefix == nil then
        return false
    end
    return value:sub(1, #prefix):lower() == prefix:lower()
end

function M.max_index(values)
    local max = 0
    for key, _ in pairs(values or {}) do
        if type(key) == "number" and key > max then
            max = key
        end
    end
    return max
end

function M.each(values, fn)
    for i = 1, M.max_index(values) do
        if values[i] ~= nil then
            fn(values[i], i)
        end
    end
end

function M.join_path(...)
    local parts = {...}
    local clean = {}
    for _, item in ipairs(parts) do
        if not M.is_blank(item) then
            clean[#clean + 1] = tostring(item)
        end
    end

    if #clean == 0 then
        return ""
    end

    if path and type(path.join) == "function" then
        local result = clean[1]
        for i = 2, #clean do
            result = path.join(result, clean[i])
        end
        return result
    end

    local result = clean[1]
    for i = 2, #clean do
        local item = clean[i]
        if result:match("[\\/]$") then
            result = result .. item
        else
            result = result .. "\\" .. item
        end
    end
    return result
end

function M.full_path(value)
    if M.is_blank(value) then
        return nil
    end
    return safe_call(os.getfullpathname, value) or value
end

function M.is_dir(value)
    if M.is_blank(value) then
        return false
    end
    return safe_call(os.isdir, value) == true
end

function M.is_file(value)
    if M.is_blank(value) then
        return false
    end
    return safe_call(os.isfile, value) == true
end

function M.home_dir()
    local home = os.getenv("USERPROFILE") or os.getenv("HOME")
    if not M.is_blank(home) then
        return home
    end

    local drive = os.getenv("HOMEDRIVE")
    local path_part = os.getenv("HOMEPATH")
    if not M.is_blank(drive) and not M.is_blank(path_part) then
        return drive .. path_part
    end

    return os.getcwd()
end

function M.env(name)
    return os.getenv(name)
end

function M.set_env(name, value)
    if M.is_blank(name) then
        return false
    end
    if value == nil then
        value = ""
    end
    return safe_call(os.setenv, name, tostring(value)) == true
end

function M.set_env_if_empty(name, value)
    if M.is_blank(value) then
        return false
    end
    if not M.is_blank(os.getenv(name)) then
        return false
    end
    return M.set_env(name, value)
end

function M.set_env_first_existing_dir(name, candidates)
    if not M.is_blank(os.getenv(name)) then
        return false
    end
    local selected = nil
    M.each(candidates, function(candidate)
        if selected ~= nil then
            return
        end
        if not M.is_blank(candidate) and M.is_dir(candidate) then
            selected = M.full_path(candidate)
        end
    end)
    if selected ~= nil then
        return M.set_env(name, selected)
    end
    return false
end

local function split_semicolon(value)
    local result = {}
    if M.is_blank(value) then
        return result
    end
    for item in (tostring(value) .. ";"):gmatch("([^;]*);") do
        if item ~= "" then
            result[#result + 1] = item
        end
    end
    return result
end

function M.path_entries()
    local entries = {}
    for _, entry in ipairs(split_semicolon(os.getenv("PATH") or "")) do
        entry = M.trim(entry)
        if entry ~= "" then
            entries[#entries + 1] = entry
        end
    end
    return entries
end

function M.set_path_entries(entries)
    local clean = {}
    for _, entry in ipairs(entries or {}) do
        if not M.is_blank(entry) then
            clean[#clean + 1] = entry
        end
    end
    return M.set_env("PATH", table.concat(clean, ";"))
end

local function add_path(entries, seen, value, where)
    if M.is_blank(value) then
        return
    end

    local resolved = M.full_path(value)
    if M.is_blank(resolved) or not M.is_dir(resolved) then
        return
    end

    local key = resolved:lower()
    if seen[key] then
        for i = #entries, 1, -1 do
            if entries[i]:lower() == key then
                table.remove(entries, i)
            end
        end
    end

    seen[key] = true
    if where == "append" then
        entries[#entries + 1] = resolved
    else
        table.insert(entries, 1, resolved)
    end
end

function M.add_path_prepend(values)
    local entries = M.path_entries()
    local seen = {}
    for _, entry in ipairs(entries) do
        seen[entry:lower()] = true
    end
    M.each(values, function(value)
        add_path(entries, seen, value, "prepend")
    end)
    return M.set_path_entries(entries)
end

function M.add_path_append(values)
    local entries = M.path_entries()
    local seen = {}
    for _, entry in ipairs(entries) do
        seen[entry:lower()] = true
    end
    M.each(values, function(value)
        add_path(entries, seen, value, "append")
    end)
    return M.set_path_entries(entries)
end

function M.add_path_prepend_value(value)
    local entries = M.path_entries()
    local seen = {}
    local merged = {}

    for _, item in ipairs(split_semicolon(value)) do
        merged[#merged + 1] = item
    end
    for _, item in ipairs(entries) do
        merged[#merged + 1] = item
    end

    local clean = {}
    for _, item in ipairs(merged) do
        if not M.is_blank(item) then
            local resolved = M.full_path(item)
            if not M.is_blank(resolved) and M.is_dir(resolved) then
                local key = resolved:lower()
                if not seen[key] then
                    seen[key] = true
                    clean[#clean + 1] = resolved
                end
            end
        end
    end

    return M.set_path_entries(clean)
end

function M.read_lines(file)
    local lines = {}
    if M.is_blank(file) or not M.is_file(file) then
        return lines
    end

    local handle = io.open(file, "r")
    if not handle then
        return lines
    end
    for line in handle:lines() do
        lines[#lines + 1] = line
    end
    handle:close()
    return lines
end

function M.print(value)
    if clink and type(clink.print) == "function" then
        clink.print(tostring(value or ""))
    else
        print(tostring(value or ""))
    end
end

function M.print_lines(lines)
    for _, line in ipairs(lines or {}) do
        M.print(line)
    end
end

if settings and type(settings.set) == "function" then
    safe_call(settings.set, "cmd.get_errorlevel", true)
end
