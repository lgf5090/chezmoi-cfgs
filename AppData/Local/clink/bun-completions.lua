--------------------------------------------------------------------------------
-- Static bun completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local scripts = { "start", "test", "build", "dev", "lint", "format", "typecheck", "preview" }
local packages = { "PACKAGE", "typescript", "vite", "eslint", "prettier", "react", "vue", "next" }

C.register({ "bun", "bun.exe" }, function(parser)
    C.apply(parser, {
        flags = {
            "-h", "--help", "-v", "--version",
            "--cwd" .. C.dir_arg(),
            "--config" .. C.file_arg(),
            "--watch", "--hot",
            "--env-file" .. C.file_arg(),
        },
        args = {
            "add" .. C.parser({ flags = { "-d", "--dev", "-p", "--peer", "-g", "--global", "-E", "--exact", "--backend" .. C.values({ "clonefile", "hardlink", "copyfile", "symlink" }) }, args = packages }),
            "audit" .. C.parser({ flags = { "--json", "--audit-level" .. C.values({ "low", "moderate", "high", "critical" }) } }),
            "build" .. C.parser({ flags = { "--outdir" .. C.dir_arg(), "--target" .. C.values({ "browser", "bun", "node" }), "--format" .. C.values({ "esm", "cjs", "iife" }), "--minify", "--sourcemap" }, args = clink.filematches }),
            "create" .. C.parser({ args = packages }),
            "dev" .. C.parser({ args = scripts }),
            "fig",
            "init" .. C.parser({ flags = { "-y", "--yes" } }),
            "install" .. C.parser({ flags = { "--frozen-lockfile", "--lockfile-only", "--production", "--no-save", "--ignore-scripts", "--backend" .. C.values({ "clonefile", "hardlink", "copyfile", "symlink" }) } }),
            "link" .. C.parser({ args = packages }),
            "outdated" .. C.parser({ flags = { "--filter" .. C.values({ "pattern" }) }, args = packages }),
            "pm" .. C.parser({ args = { "bin", "cache", "hash", "ls", "migration", "pack", "pkg", "trust", "untrusted" } }),
            "publish" .. C.parser({ flags = { "--tag" .. C.values({ "latest", "next", "beta" }), "--access" .. C.values({ "public", "restricted" }), "--dry-run" } }),
            "remove" .. C.parser({ flags = { "-g", "--global" }, args = packages }),
            "run" .. C.parser({ args = scripts }),
            "test" .. C.parser({ flags = { "--watch", "--coverage", "--timeout" .. C.values({ "5000" }), "--bail" .. C.values({ "1" }), "--filter" .. C.values({ "pattern" }) }, args = clink.filematches }),
            "update" .. C.parser({ flags = { "--latest", "--interactive" }, args = packages }),
            "upgrade",
            "x" .. C.parser({ args = packages }),
        },
    })
end)

