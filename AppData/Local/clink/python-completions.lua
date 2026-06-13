--------------------------------------------------------------------------------
-- Static python/py completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local modules = {
    "pip", "venv", "http.server", "unittest", "pytest", "pdb", "pydoc",
    "site", "json.tool", "ensurepip", "compileall", "zipapp", "build",
    "twine", "black", "ruff", "mypy",
}

local parser_spec = {
    flags = {
        "-h", "--help", "-V", "--version",
        "-c" .. C.values({ "command" }),
        "-m" .. C.values(modules),
        "-i", "-I", "-O", "-OO", "-q", "-s", "-S", "-u", "-v",
        "-W" .. C.values({ "default", "ignore", "error", "always", "module", "once" }),
        "-X" .. C.values({ "dev", "faulthandler", "importtime", "tracemalloc", "utf8" }),
        "--check-hash-based-pycs" .. C.values({ "default", "always", "never" }),
    },
    args = clink.filematches,
}

C.register({ "python", "python.exe", "python3", "python3.exe" }, function(parser)
    C.apply(parser, parser_spec)
end)

C.register({ "py", "py.exe" }, function(parser)
    C.apply(parser, {
        flags = {
            "-h", "--help", "-V", "--version",
            "-0", "-0p", "-2", "-3", "-3.11", "-3.12", "-3.13",
            "-m" .. C.values(modules),
            "-c" .. C.values({ "command" }),
        },
        args = clink.filematches,
    })
end)

