--------------------------------------------------------------------------------
-- Static node completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local modules = {
    "fs", "path", "os", "http", "https", "url", "util", "events", "stream",
    "crypto", "child_process", "worker_threads", "node:test",
}

C.register({ "node", "node.exe" }, function(parser)
    C.apply(parser, {
        flags = {
            "-h", "--help", "-v", "--version",
            "-e" .. C.values({ "script" }), "--eval" .. C.values({ "script" }),
            "-p" .. C.values({ "script" }), "--print" .. C.values({ "script" }),
            "-c", "--check", "-i", "--interactive",
            "-r" .. C.values(modules), "--require" .. C.values(modules),
            "--import" .. C.values(modules),
            "--loader" .. C.values({ "loader" }),
            "--inspect", "--inspect-brk", "--inspect-port" .. C.values({ "9229" }),
            "--watch", "--watch-path" .. C.dir_arg(), "--watch-preserve-output",
            "--test", "--test-name-pattern" .. C.values({ "pattern" }),
            "--enable-source-maps", "--trace-warnings", "--throw-deprecation",
            "--no-warnings", "--unhandled-rejections" .. C.values({ "strict", "throw", "warn", "none" }),
            "--experimental-strip-types", "--experimental-transform-types",
            "--env-file" .. C.file_arg(),
        },
        args = clink.filematches,
    })
end)

