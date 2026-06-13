--------------------------------------------------------------------------------
-- Static yarn completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local scripts = { "start", "test", "build", "dev", "lint", "format", "typecheck", "preview", "serve", "watch" }
local packages = { "PACKAGE", "typescript", "vite", "eslint", "prettier", "react", "vue", "next" }

C.register({ "yarn", "yarn.cmd" }, function(parser)
    C.apply(parser, {
        flags = {
            "-h", "--help", "-v", "--version", "--cwd" .. C.dir_arg(),
            "--silent", "--verbose", "--json", "--offline",
            "--registry" .. C.values({ "https://registry.yarnpkg.com/" }),
        },
        args = {
            "add" .. C.parser({ flags = { "-D", "--dev", "-P", "--peer", "-O", "--optional", "-E", "--exact", "-T", "--tilde", "--cached", "--interactive" }, args = packages }),
            "audit" .. C.parser({ flags = { "--groups" .. C.values({ "dependencies", "devDependencies" }), "--level" .. C.values({ "low", "moderate", "high", "critical" }) } }),
            "bin" .. C.parser({ args = packages }),
            "cache" .. C.parser({ args = { "clean", "dir", "list" } }),
            "config" .. C.parser({ args = { "get", "set", "unset", "current" } }),
            "constraints" .. C.parser({ args = { "source", "query" } }),
            "dedupe" .. C.parser({ flags = { "--strategy" .. C.values({ "highest" }), "--check" }, args = packages }),
            "dlx" .. C.parser({ flags = { "-p" .. C.values(packages), "--package" .. C.values(packages), "-q", "--quiet" }, args = packages }),
            "exec" .. C.parser({ args = packages }),
            "explain" .. C.parser({ args = { "peer-requirements" } }),
            "info" .. C.parser({ flags = { "--json", "--name-only" }, args = packages }),
            "init" .. C.parser({ flags = { "-y", "--yes", "-p", "--private", "-w", "--workspace" } }),
            "install" .. C.parser({ flags = { "--immutable", "--immutable-cache", "--check-cache", "--mode" .. C.values({ "skip-builds", "update-lockfile" }) } }),
            "link" .. C.parser({ flags = { "-A", "--all", "-p", "--private", "-r", "--relative" }, args = clink.dirmatches }),
            "node" .. C.parser({ args = clink.filematches }),
            "npm" .. C.parser({ args = { "audit", "info", "login", "logout", "publish", "tag", "whoami" } }),
            "pack" .. C.parser({ flags = { "--install-if-needed", "-o" .. C.file_arg(), "--out" .. C.file_arg() } }),
            "plugin" .. C.parser({ args = { "import", "list", "remove", "runtime" } }),
            "rebuild" .. C.parser({ args = packages }),
            "remove" .. C.parser({ flags = { "-A", "--all", "--mode" .. C.values({ "skip-builds", "update-lockfile" }) }, args = packages }),
            "run" .. C.parser({ args = scripts }),
            "search" .. C.parser({ args = packages }),
            "set" .. C.parser({ args = { "version" } }),
            "test" .. C.parser({ args = scripts }),
            "unlink" .. C.parser({ flags = { "-A", "--all" }, args = clink.dirmatches }),
            "up" .. C.parser({ flags = { "-i", "--interactive", "-R", "--recursive", "--mode" .. C.values({ "skip-builds", "update-lockfile" }) }, args = packages }),
            "upgrade" .. C.parser({ flags = { "--latest", "--pattern" .. C.values({ "pattern" }) }, args = packages }),
            "why" .. C.parser({ args = packages }),
            "workspace" .. C.parser({ args = { "WORKSPACE", "add", "remove", "run" } }),
            "workspaces" .. C.parser({ args = { "focus", "foreach", "list" } }),
        },
    })
end)

