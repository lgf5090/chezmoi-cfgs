--------------------------------------------------------------------------------
-- Static deno completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local permissions = {
    "--allow-all", "-A",
    "--allow-env", "--allow-ffi", "--allow-hrtime", "--allow-net",
    "--allow-read", "--allow-run", "--allow-sys", "--allow-write",
    "--deny-env", "--deny-ffi", "--deny-hrtime", "--deny-net",
    "--deny-read", "--deny-run", "--deny-sys", "--deny-write",
    "--no-prompt",
}

local run_flags = {
    "--watch", "--check", "--no-check", "--cached-only",
    "--config" .. C.file_arg(), "--import-map" .. C.file_arg(),
    "--env-file" .. C.file_arg(),
    "--location" .. C.values({ "http://localhost" }),
    "--cert" .. C.file_arg(),
    "--inspect", "--inspect-brk", "--inspect-wait",
    "--unstable", "--v8-flags" .. C.values({ "flags" }),
}
for _, flag in ipairs(permissions) do
    run_flags[#run_flags + 1] = flag
end

C.register({ "deno", "deno.exe" }, function(parser)
    C.apply(parser, {
        flags = { "-h", "--help", "-V", "--version", "--quiet", "--log-level" .. C.values({ "debug", "info" }) },
        args = {
            "add" .. C.parser({ args = { "jsr:", "npm:" }, flags = { "--dev", "--config" .. C.file_arg(), "--lock" .. C.file_arg() } }),
            "bench" .. C.parser({ flags = run_flags, args = clink.filematches }),
            "bundle" .. C.parser({ flags = { "--config" .. C.file_arg(), "--import-map" .. C.file_arg(), "--no-check" }, args = clink.filematches }),
            "cache" .. C.parser({ flags = { "--reload", "--lock" .. C.file_arg(), "--config" .. C.file_arg(), "--import-map" .. C.file_arg() }, args = clink.filematches }),
            "check" .. C.parser({ flags = { "--config" .. C.file_arg(), "--import-map" .. C.file_arg(), "--reload" }, args = clink.filematches }),
            "clean",
            "compile" .. C.parser({ flags = run_flags, args = clink.filematches }),
            "completions" .. C.parser({ args = { "bash", "fish", "powershell", "zsh" } }),
            "coverage" .. C.parser({ flags = { "--html", "--lcov", "--output" .. C.dir_arg(), "--include" .. C.values({ "pattern" }), "--exclude" .. C.values({ "pattern" }) }, args = clink.dirmatches }),
            "doc" .. C.parser({ flags = { "--html", "--json", "--output" .. C.dir_arg(), "--lint", "--private" }, args = clink.filematches }),
            "eval" .. C.parser({ flags = run_flags, args = { "code" } }),
            "fmt" .. C.parser({ flags = { "--check", "--watch", "--config" .. C.file_arg(), "--ignore" .. C.values({ "path" }), "--ext" .. C.values({ "ts", "js", "tsx", "jsx", "json", "md" }) }, args = clink.filematches }),
            "info" .. C.parser({ flags = { "--json", "--reload", "--config" .. C.file_arg() }, args = clink.filematches }),
            "init" .. C.parser({ flags = { "--lib", "--serve", "--npm", "--package" }, args = clink.dirmatches }),
            "install" .. C.parser({ flags = run_flags, args = clink.filematches }),
            "jupyter" .. C.parser({ args = { "kernel", "kernelspec" } }),
            "lint" .. C.parser({ flags = { "--fix", "--rules", "--json", "--watch", "--config" .. C.file_arg(), "--ignore" .. C.values({ "path" }) }, args = clink.filematches }),
            "lsp",
            "outdated" .. C.parser({ flags = { "--update", "--latest", "--compatible", "--recursive" } }),
            "remove" .. C.parser({ args = { "PACKAGE" } }),
            "repl" .. C.parser({ flags = run_flags }),
            "run" .. C.parser({ flags = run_flags, args = clink.filematches }),
            "serve" .. C.parser({ flags = run_flags, args = clink.filematches }),
            "task" .. C.parser({ args = { "start", "test", "build", "dev", "lint", "fmt" } }),
            "test" .. C.parser({ flags = run_flags, args = clink.filematches }),
            "types",
            "upgrade" .. C.parser({ flags = { "--version" .. C.values({ "stable", "canary" }), "--canary", "--force", "--output" .. C.file_arg() } }),
            "vendor" .. C.parser({ flags = { "--output" .. C.dir_arg(), "--force" }, args = clink.filematches }),
        },
    })
end)

