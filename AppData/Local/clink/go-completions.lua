--------------------------------------------------------------------------------
-- Static go completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local packages = { ".", "./...", "std", "cmd", "all" }
local build_flags = {
    "-C" .. C.dir_arg(), "-a", "-n", "-p" .. C.values({ "4" }), "-race",
    "-msan", "-asan", "-cover", "-covermode" .. C.values({ "set", "count", "atomic" }),
    "-coverpkg" .. C.values(packages),
    "-v", "-work", "-x",
    "-asmflags" .. C.values({ "pattern=arg list" }),
    "-buildmode" .. C.values({ "archive", "c-archive", "c-shared", "default", "exe", "pie", "plugin", "shared" }),
    "-buildvcs" .. C.values({ "auto", "true", "false" }),
    "-compiler" .. C.values({ "gc", "gccgo" }),
    "-gccgoflags" .. C.values({ "arg list" }),
    "-gcflags" .. C.values({ "pattern=arg list" }),
    "-installsuffix" .. C.values({ "suffix" }),
    "-ldflags" .. C.values({ "arg list" }),
    "-linkshared", "-mod" .. C.values({ "readonly", "vendor", "mod" }),
    "-modfile" .. C.file_arg(),
    "-overlay" .. C.file_arg(),
    "-pkgdir" .. C.dir_arg(),
    "-tags" .. C.values({ "tag,list" }),
    "-trimpath",
}

C.register({ "go", "go.exe" }, function(parser)
    C.apply(parser, {
        flags = { "-C" .. C.dir_arg(), "-h", "--help" },
        args = {
            "bug",
            "build" .. C.parser({ flags = build_flags, args = packages }),
            "clean" .. C.parser({ flags = { "-cache", "-testcache", "-modcache", "-fuzzcache", "-i", "-n", "-r", "-x" }, args = packages }),
            "doc" .. C.parser({ flags = { "-all", "-cmd", "-short", "-src", "-u" }, args = packages }),
            "env" .. C.parser({ flags = { "-json", "-u", "-w" }, args = { "GOOS", "GOARCH", "GOPATH", "GOROOT", "GOMOD", "GOMODCACHE", "GONOSUMDB", "GOPROXY", "GOVERSION" } }),
            "fmt" .. C.parser({ flags = { "-n", "-x" }, args = packages }),
            "generate" .. C.parser({ flags = { "-run" .. C.values({ "regexp" }), "-skip" .. C.values({ "regexp" }), "-n", "-v", "-x" }, args = packages }),
            "get" .. C.parser({ flags = { "-t", "-u", "-v" }, args = { "module", "module@latest", "module@version" } }),
            "help" .. C.parser({ args = { "build", "buildconstraint", "buildmode", "cache", "environment", "filetype", "go.mod", "gopath", "goproxy", "importpath", "modules", "module-get", "packages", "testflag" } }),
            "install" .. C.parser({ flags = build_flags, args = { "module", "module@latest", "module@version", "./..." } }),
            "list" .. C.parser({ flags = { "-json", "-m", "-u", "-versions", "-deps", "-e", "-f" .. C.values({ "{{.ImportPath}}" }), "-test" }, args = packages }),
            "mod" .. C.parser({ args = {
                "download" .. C.parser({ flags = { "-json", "-x" }, args = packages }),
                "edit" .. C.parser({ flags = { "-fmt", "-module" .. C.values({ "module/path" }), "-go" .. C.values({ "1.22", "1.23" }), "-require" .. C.values({ "module@version" }), "-droprequire" .. C.values({ "module" }), "-replace" .. C.values({ "old=new" }), "-dropreplace" .. C.values({ "module" }) } }),
                "graph",
                "init" .. C.parser({ args = { "module/path" } }),
                "tidy" .. C.parser({ flags = { "-e", "-v", "-x" } }),
                "vendor" .. C.parser({ flags = { "-e", "-v", "-o" .. C.dir_arg() } }),
                "verify",
                "why" .. C.parser({ flags = { "-m" }, args = packages }),
            } }),
            "run" .. C.parser({ flags = build_flags, args = clink.filematches }),
            "test" .. C.parser({ flags = {
                "-bench" .. C.values({ ".", "BenchmarkName" }), "-benchmem",
                "-count" .. C.values({ "1" }), "-cover", "-coverprofile" .. C.file_arg(),
                "-failfast", "-json", "-list" .. C.values({ "." }), "-run" .. C.values({ ".", "TestName" }),
                "-short", "-shuffle" .. C.values({ "on", "off" }), "-timeout" .. C.values({ "30s" }),
                "-v",
            }, args = packages }),
            "tool" .. C.parser({ args = { "addr2line", "asm", "buildid", "cgo", "compile", "cover", "dist", "doc", "fix", "link", "nm", "objdump", "pack", "pprof", "test2json", "trace", "vet" } }),
            "version",
            "vet" .. C.parser({ flags = { "-json", "-printf", "-unreachable", "-unusedresult" }, args = packages }),
            "work" .. C.parser({ args = { "edit", "init", "sync", "use", "vendor" } }),
        },
    })
end)

