--------------------------------------------------------------------------------
-- Shared helpers for static Clink completions.
--
-- Completion scripts in this profile intentionally avoid running external
-- commands.  They provide static subcommands/flags plus Clink's built-in file
-- and directory matchers.

shells_completions = shells_completions or {}

local C = shells_completions

function C.available()
    return clink and type(clink.argmatcher) == "function"
end

function C.values(values, nofiles)
    local parser = clink.argmatcher()
    if values then
        parser:addarg(values)
    end
    if nofiles and type(parser.nofiles) == "function" then
        parser:nofiles()
    end
    return parser
end

function C.file_arg()
    return C.values(clink.filematches)
end

function C.dir_arg()
    return C.values(clink.dirmatches)
end

function C.apply(parser, spec)
    spec = spec or {}
    if spec.flags then
        parser:addflags(spec.flags)
    end
    if spec.args then
        parser:addarg(spec.args)
    end
    if spec.nofiles and type(parser.nofiles) == "function" then
        parser:nofiles()
    end
    if spec.flagsanywhere and type(parser.setflagsanywhere) == "function" then
        parser:setflagsanywhere(true)
    end
    return parser
end

function C.parser(spec)
    return C.apply(clink.argmatcher(), spec)
end

function C.register(commands, builder)
    if not C.available() then
        return
    end
    if type(commands) == "string" then
        commands = { commands }
    end
    for _, command in ipairs(commands or {}) do
        builder(clink.argmatcher(command), command)
    end
end

