--------------------------------------------------------------------------------
-- Static pnpm completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local scripts = { "start", "test", "build", "dev", "lint", "format", "typecheck", "preview", "serve", "watch" }
local packages = { "PACKAGE", "typescript", "vite", "eslint", "prettier", "react", "vue", "next" }

C.register({ "pnpm", "pnpm.cmd" }, function(parser)
    C.apply(parser, {
        flags = {
            "-h", "--help", "-v", "--version",
            "--dir" .. C.dir_arg(), "-C" .. C.dir_arg(),
            "--workspace-root", "-w", "--filter" .. C.values({ "package", "...", "./packages/*" }),
            "--color" .. C.values({ "auto", "always", "never" }),
            "--config" .. C.values({ "key=value" }),
            "--registry" .. C.values({ "https://registry.npmjs.org/" }),
        },
        args = {
            "add" .. C.parser({ flags = { "-D", "--save-dev", "-O", "--save-optional", "-P", "--save-prod", "-E", "--save-exact", "-g", "--global", "--workspace", "--filter" .. C.values({ "package" }) }, args = packages }),
            "approve-builds",
            "audit" .. C.parser({ flags = { "--fix", "--json", "--audit-level" .. C.values({ "low", "moderate", "high", "critical" }) } }),
            "build" .. C.parser({ args = scripts }),
            "catalog" .. C.parser({ args = { "add", "remove", "update" } }),
            "config" .. C.parser({ args = { "get", "set", "delete", "list" }, flags = { "-g", "--global" } }),
            "create" .. C.parser({ args = packages }),
            "deploy" .. C.parser({ flags = { "--filter" .. C.values({ "package" }), "--prod", "--dev-optional" }, args = clink.dirmatches }),
            "dlx" .. C.parser({ flags = { "--package" .. C.values(packages), "--allow-build" .. C.values(packages) }, args = packages }),
            "env" .. C.parser({ args = { "use", "remove", "list" } }),
            "exec" .. C.parser({ flags = { "--recursive", "-r", "--filter" .. C.values({ "package" }) }, args = packages }),
            "fetch" .. C.parser({ flags = { "--prod", "--dev", "--filter" .. C.values({ "package" }) } }),
            "import",
            "init" .. C.parser({ flags = { "--init-package-manager", "--init-type" .. C.values({ "commonjs", "module" }) } }),
            "install" .. C.parser({ flags = { "--frozen-lockfile", "--lockfile-only", "--offline", "--prod", "--dev", "--ignore-scripts", "--filter" .. C.values({ "package" }) } }),
            "link" .. C.parser({ flags = { "-g", "--global" }, args = packages }),
            "list" .. C.parser({ flags = { "-r", "--recursive", "--depth" .. C.values({ "0", "1", "2" }), "--json", "--long", "--parseable" }, args = packages }),
            "outdated" .. C.parser({ flags = { "-r", "--recursive", "--format" .. C.values({ "table", "list", "json" }) }, args = packages }),
            "patch" .. C.parser({ args = packages }),
            "patch-commit" .. C.parser({ args = clink.dirmatches }),
            "prune" .. C.parser({ flags = { "--prod", "--no-optional" } }),
            "publish" .. C.parser({ flags = { "--tag" .. C.values({ "latest", "next", "beta" }), "--access" .. C.values({ "public", "restricted" }), "--dry-run" } }),
            "rebuild" .. C.parser({ args = packages }),
            "remove" .. C.parser({ flags = { "-D", "--save-dev", "-O", "--save-optional", "-P", "--save-prod", "-g", "--global" }, args = packages }),
            "run" .. C.parser({ args = scripts, flags = { "-r", "--recursive", "--filter" .. C.values({ "package" }), "--if-present" } }),
            "setup",
            "store" .. C.parser({ args = { "add", "path", "prune", "status" } }),
            "test" .. C.parser({ flags = { "--if-present", "--filter" .. C.values({ "package" }) } }),
            "unlink" .. C.parser({ flags = { "-g", "--global" }, args = packages }),
            "update" .. C.parser({ flags = { "-r", "--recursive", "-i", "--interactive", "--latest", "-g", "--global" }, args = packages }),
            "why" .. C.parser({ args = packages }),
        },
    })
end)

