--------------------------------------------------------------------------------
-- Clink-native command helpers.
--
-- Commands here are handled by clink.onfilterinput() before CMD runs the line.
-- They do not call external programs.

local S = shells
if not S or not clink or type(clink.onfilterinput) ~= "function" then
    return
end

local commands = {}

math.randomseed(os.time() + (S.safe_call(os.getpid) or 0))

local function show_usage(lines)
    S.print_lines(lines)
    return true
end

local function tokenize(line)
    local args = {}
    local current = {}
    local quote = nil
    local i = 1

    while i <= #line do
        local c = line:sub(i, i)
        if quote then
            if c == quote then
                quote = nil
            else
                current[#current + 1] = c
            end
        else
            if c == '"' or c == "'" then
                quote = c
            elseif c:match("%s") then
                if #current > 0 then
                    args[#args + 1] = table.concat(current)
                    current = {}
                end
            else
                current[#current + 1] = c
            end
        end
        i = i + 1
    end

    if #current > 0 then
        args[#args + 1] = table.concat(current)
    end
    return args
end

local function contains_cmd_meta(line)
    local quote = nil
    for i = 1, #line do
        local c = line:sub(i, i)
        if quote then
            if c == quote then
                quote = nil
            end
        elseif c == '"' or c == "'" then
            quote = c
        elseif c == "|" or c == "&" or c == "<" or c == ">" then
            return true
        end
    end
    return false
end

local function first_word_rest(line)
    local args = tokenize(line)
    if #args == 0 then
        return nil, ""
    end

    local word = args[1]
    local rest = line:match("^%s*%S+%s*(.*)$") or ""
    return word, rest
end

local function append_rest(command, rest)
    if S.is_blank(rest) then
        return command
    end
    return command .. " " .. rest
end

local function cmd_quote(value)
    value = tostring(value or ""):gsub('"', '\\"')
    return '"' .. value .. '"'
end

local function positive_int(value, label)
    local n = tonumber(value)
    if not n or n < 1 or math.floor(n) ~= n then
        return nil, label .. " requires a positive integer"
    end
    return n
end

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

local function mkdirs(dir)
    if S.is_blank(dir) then
        return false, "missing directory"
    end
    if S.is_dir(dir) then
        return true
    end

    local ok, err = S.safe_call(os.mkdir, dir)
    if ok == true or S.is_dir(dir) then
        return true
    end

    local parent = parent_dir(dir)
    if parent and not S.is_dir(parent) then
        local parent_ok, parent_err = mkdirs(parent)
        if not parent_ok then
            return false, parent_err
        end
    end

    ok, err = S.safe_call(os.mkdir, dir)
    if ok == true or S.is_dir(dir) then
        return true
    end
    return false, err or "cannot create directory"
end

local function format_guid(raw)
    if S.is_blank(raw) or #raw < 32 then
        return nil
    end
    raw = raw:lower()
    return table.concat({
        raw:sub(1, 8),
        raw:sub(9, 12),
        raw:sub(13, 16),
        raw:sub(17, 20),
        raw:sub(21, 32),
    }, "-")
end

local function new_guid()
    local raw = S.safe_call(os.createguid)
    return format_guid(raw)
end

local function guid_bytes()
    local raw = S.safe_call(os.createguid)
    local bytes = {}
    if not S.is_blank(raw) then
        for i = 1, #raw - 1, 2 do
            bytes[#bytes + 1] = tonumber(raw:sub(i, i + 1), 16) or math.random(0, 255)
        end
    end
    if #bytes == 0 then
        for _ = 1, 16 do
            bytes[#bytes + 1] = math.random(0, 255)
        end
    end
    return bytes
end

local function random_string(length, alphabet)
    local out = {}
    while #out < length do
        for _, byte in ipairs(guid_bytes()) do
            local index = (byte % #alphabet) + 1
            out[#out + 1] = alphabet:sub(index, index)
            if #out >= length then
                break
            end
        end
    end
    return table.concat(out)
end

local function collect_matches(pattern, extrainfo, flags)
    local ff = S.safe_call(os.findfiles, pattern, extrainfo, flags)
    local items = {}
    if not ff or type(ff.files) ~= "function" then
        return items
    end

    for item in ff:files() do
        items[#items + 1] = item
    end
    if type(ff.close) == "function" then
        ff:close()
    end
    return items
end

local function item_name(item)
    if type(item) == "table" then
        return item.name or ""
    end
    return tostring(item or "")
end

local function is_dir_item(item)
    return type(item) == "table" and type(item.type) == "string" and item.type:find("dir", 1, true) ~= nil
end

local function list_items(args, by_time)
    local patterns = {}
    for i = 2, #args do
        patterns[#patterns + 1] = args[i]
    end
    if #patterns == 0 then
        patterns[1] = "*"
    end

    local items = {}
    for _, pattern in ipairs(patterns) do
        local matches = collect_matches(pattern, 2, {
            files = true,
            dirs = true,
            hidden = true,
            system = false,
            dirsuffix = false,
        })
        for _, item in ipairs(matches) do
            items[#items + 1] = item
        end
    end

    table.sort(items, function(a, b)
        if by_time then
            local am = type(a) == "table" and a.mtime or 0
            local bm = type(b) == "table" and b.mtime or 0
            if am ~= bm then
                return am > bm
            end
        end
        return item_name(a):lower() < item_name(b):lower()
    end)

    for _, item in ipairs(items) do
        local name = item_name(item)
        local marker = is_dir_item(item) and "\\" or ""
        local when = type(item) == "table" and item.mtime and os.date("%Y-%m-%d %H:%M", item.mtime) or "                "
        local size = "<DIR>"
        if not is_dir_item(item) and type(item) == "table" and item.size then
            size = tostring(item.size)
        end
        S.print(string.format("%s %10s %s%s", when, size, name, marker))
    end
    return true
end

local function expand_file_patterns(patterns)
    local files = {}
    for _, pattern in ipairs(patterns) do
        local matches = collect_matches(pattern, 1, {
            files = true,
            dirs = false,
            hidden = true,
            system = false,
            dirsuffix = false,
        })
        for _, item in ipairs(matches) do
            files[#files + 1] = item_name(item)
        end
    end
    return files
end

commands["l"] = function(_, rest)
    return append_rest("dir", rest)
end

commands["ll"] = function(_, rest)
    return append_rest("dir /a", rest)
end

commands["la"] = function(_, rest)
    return append_rest("dir /a", rest)
end

commands["lt"] = function(_, rest)
    return append_rest("dir /a /o-d", rest)
end

commands[".."] = function()
    return "cd /d .."
end

commands["..."] = function()
    return "cd /d ..\\.."
end

commands["...."] = function()
    return "cd /d ..\\..\\.."
end

commands["mkdirp"] = function(_, rest)
    if S.is_blank(rest) then
        return show_usage({ "usage: mkdirp <dir> [dir ...]" })
    end
    return append_rest("mkdir", rest)
end

commands["md"] = commands["mkdirp"]

commands["mkcd"] = function(args)
    if #args ~= 2 then
        return show_usage({ "usage: mkcd <dir>" })
    end
    local target = cmd_quote(args[2])
    return "mkdir " .. target .. " 2>nul & cd /d " .. target
end

commands["now"] = function()
    S.print(os.date("%Y-%m-%dT%H:%M:%S%z"))
    return true
end

commands["paths"] = function()
    S.print_lines(S.path_entries())
    return true
end

commands["cls"] = function()
    return "cls"
end

commands["clear"] = commands["cls"]

commands["proxy"] = function(args)
    local host = args[2] or S.env("PROXY_HOST") or "127.0.0.1"
    local port = args[3] or S.env("PROXY_PORT") or "3067"
    local url = "http://" .. host .. ":" .. port
    S.set_env("http_proxy", url)
    S.set_env("https_proxy", url)
    S.set_env("HTTP_PROXY", url)
    S.set_env("HTTPS_PROXY", url)
    S.print("proxy on (" .. host .. ":" .. port .. ")")
    return true
end

commands["socks5"] = function(args)
    local host = args[2] or S.env("PROXY_HOST") or "127.0.0.1"
    local port = args[3] or S.env("PROXY_PORT") or "3067"
    local url = "socks5://" .. host .. ":" .. port
    S.set_env("all_proxy", url)
    S.set_env("ALL_PROXY", url)
    S.print("socks5 on (" .. host .. ":" .. port .. ")")
    return true
end

commands["unproxy"] = function()
    for _, name in ipairs({
        "http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY",
        "all_proxy", "ALL_PROXY",
    }) do
        S.set_env(name, "")
    end
    S.print("proxy off")
    return true
end

commands["proxyinfo"] = function()
    local function value(name)
        local v = S.env(name)
        if S.is_blank(v) then
            return "unset"
        end
        return v
    end
    S.print("http : " .. value("http_proxy"))
    S.print("https: " .. value("https_proxy"))
    S.print("socks: " .. value("all_proxy"))
    return true
end

commands["uuid"] = function(args)
    local count = 1
    local i = 2
    while i <= #args do
        local arg = args[i]
        if arg == "-h" or arg == "--help" then
            return show_usage({
                "usage: uuid [-n COUNT]",
                "Generate UUIDs using Clink's os.createguid().",
            })
        elseif arg == "-n" or arg == "--count" then
            i = i + 1
            local n, err = positive_int(args[i], arg)
            if not n then
                S.print("uuid: " .. err)
                return true
            end
            count = n
        else
            S.print("uuid: unexpected argument: " .. tostring(arg))
            return true
        end
        i = i + 1
    end

    for _ = 1, count do
        local guid = new_guid()
        if guid then
            S.print(guid)
        else
            S.print("uuid: os.createguid() failed")
        end
    end
    return true
end

commands["randstr"] = function(args)
    local length = 16
    local count = 1
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local prefix = ""
    local suffix = ""
    local positionals = 0
    local i = 2

    while i <= #args do
        local arg = args[i]
        if arg == "-h" or arg == "--help" then
            return show_usage({
                "usage: randstr [LENGTH] [COUNT]",
                "       randstr -l LENGTH -n COUNT [options]",
                "options: --lower --upper --alpha --digits --alnum --hex --safe",
                "         --symbols --alphabet CHARS --prefix TEXT --suffix TEXT",
            })
        elseif arg == "-l" or arg == "--length" then
            i = i + 1
            local n, err = positive_int(args[i], arg)
            if not n then
                S.print("randstr: " .. err)
                return true
            end
            length = n
        elseif arg == "-n" or arg == "--count" then
            i = i + 1
            local n, err = positive_int(args[i], arg)
            if not n then
                S.print("randstr: " .. err)
                return true
            end
            count = n
        elseif arg == "--lower" then
            alphabet = "abcdefghijklmnopqrstuvwxyz"
        elseif arg == "--upper" then
            alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        elseif arg == "--alpha" then
            alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        elseif arg == "--digits" then
            alphabet = "0123456789"
        elseif arg == "--alnum" then
            alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        elseif arg == "--hex" then
            alphabet = "0123456789abcdef"
        elseif arg == "--safe" then
            alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"
        elseif arg == "--symbols" then
            alphabet = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
        elseif arg == "--alphabet" then
            i = i + 1
            if S.is_blank(args[i]) then
                S.print("randstr: --alphabet requires CHARS")
                return true
            end
            alphabet = args[i]
        elseif arg == "--prefix" then
            i = i + 1
            prefix = args[i] or ""
        elseif arg == "--suffix" then
            i = i + 1
            suffix = args[i] or ""
        elseif arg:sub(1, 1) == "-" then
            S.print("randstr: unknown option: " .. arg)
            return true
        else
            positionals = positionals + 1
            local n, err = positive_int(arg, positionals == 1 and "LENGTH" or "COUNT")
            if not n then
                S.print("randstr: " .. err)
                return true
            end
            if positionals == 1 then
                length = n
            elseif positionals == 2 then
                count = n
            else
                S.print("randstr: unexpected argument: " .. arg)
                return true
            end
        end
        i = i + 1
    end

    if #alphabet == 0 then
        S.print("randstr: alphabet must not be empty")
        return true
    end
    for _ = 1, count do
        S.print(prefix .. random_string(length, alphabet) .. suffix)
    end
    return true
end

commands["grep"] = function(args)
    if #args < 2 then
        return show_usage({
            "usage: grep LUA_PATTERN [file ...]",
            "Search text files using Lua patterns; no external grep/findstr is used.",
        })
    end

    local pattern = args[2]
    local file_patterns = {}
    for i = 3, #args do
        file_patterns[#file_patterns + 1] = args[i]
    end
    if #file_patterns == 0 then
        file_patterns[1] = "*"
    end

    for _, file in ipairs(expand_file_patterns(file_patterns)) do
        local handle = io.open(file, "r")
        if handle then
            local line_no = 0
            for line in handle:lines() do
                line_no = line_no + 1
                local ok, found = pcall(string.find, line, pattern)
                if ok and found then
                    S.print(file .. ":" .. line_no .. ":" .. line)
                elseif not ok then
                    S.print("grep: invalid Lua pattern: " .. pattern)
                    handle:close()
                    return true
                end
            end
            handle:close()
        end
    end
    return true
end

local function import_local_aliases()
    if type(os.setalias) ~= "function" then
        return
    end

    local file = S.env("CLINK_LOCAL_ALIASES_FILE")
    if S.is_blank(file) then
        file = S.env("POWERSHELL_LOCAL_ALIASES_FILE")
    end
    if S.is_blank(file) then
        file = S.join_path(S.home_dir(), ".aliases")
    end

    for _, raw in ipairs(S.read_lines(file)) do
        local line = raw:match("^%s*(.*)$") or ""
        if line ~= "" and line:sub(1, 1) ~= "#" then
            local eq = line:find("=", 1, true)
            if eq and eq > 1 then
                local name = S.trim(line:sub(1, eq - 1))
                local body = S.strip_outer_quotes(line:sub(eq + 1))
                if name:match("^[A-Za-z_][A-Za-z0-9_.-]*$") and body ~= "" then
                    if not body:find("%$[%*123456789]") then
                        body = body .. " $*"
                    end
                    S.safe_call(os.setalias, name, body)
                end
            end
        end
    end
end

clink.onfilterinput(function(line)
    if S.is_blank(line) then
        return nil
    end

    local trimmed = S.trim(line)
    local command = first_word_rest(trimmed)
    if S.is_blank(command) then
        return nil
    end

    local _, rest = first_word_rest(trimmed)
    local args = tokenize(trimmed)
    local name = command:lower()
    local handler = commands[name]
    if not handler then
        return nil
    end

    if contains_cmd_meta(trimmed) then
        return nil
    end

    local replacement = handler(args, rest, trimmed)
    if type(replacement) == "string" then
        return replacement, false
    end
    return "", false
end)

import_local_aliases()
