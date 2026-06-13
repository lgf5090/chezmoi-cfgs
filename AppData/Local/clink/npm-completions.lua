--------------------------------------------------------------------------------
-- Static npm and npx completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local scripts = { "start", "test", "build", "dev", "lint", "format", "typecheck", "preview", "serve", "watch", "clean" }
local packages = { "PACKAGE", "typescript", "vite", "eslint", "prettier", "react", "vue", "next", "express" }

local common_flags = {
    "-h", "--help", "-v", "--version",
    "--silent", "--verbose", "--json", "--dry-run",
    "--prefix" .. C.dir_arg(),
    "--userconfig" .. C.file_arg(),
    "--registry" .. C.values({ "https://registry.npmjs.org/" }),
}

local install_flags = {
    "-D", "--save-dev", "-P", "--save-prod", "-O", "--save-optional",
    "-E", "--save-exact", "-g", "--global",
    "--no-save", "--package-lock", "--package-lock-only",
    "--legacy-peer-deps", "--strict-peer-deps", "--omit" .. C.values({ "dev", "optional", "peer" }),
    "--include" .. C.values({ "dev", "optional", "peer" }),
}

C.register({ "npm", "npm.cmd" }, function(parser)
    C.apply(parser, {
        flags = common_flags,
        args = {
            "access" .. C.parser({ args = { "grant", "revoke", "ls-packages", "ls-collaborators", "edit" } }),
            "adduser" .. C.parser({ flags = { "--registry" .. C.values({ "https://registry.npmjs.org/" }), "--scope" .. C.values({ "@scope" }) } }),
            "audit" .. C.parser({ flags = { "--fix", "--force", "--json", "--audit-level" .. C.values({ "low", "moderate", "high", "critical" }), "--omit" .. C.values({ "dev", "optional", "peer" }) } }),
            "bin" .. C.parser({ flags = { "-g", "--global" } }),
            "cache" .. C.parser({ args = { "add", "clean", "verify" }, flags = { "--force" } }),
            "ci" .. C.parser({ flags = { "--ignore-scripts", "--omit" .. C.values({ "dev", "optional", "peer" }), "--include" .. C.values({ "dev", "optional", "peer" }) } }),
            "config" .. C.parser({ args = { "get", "set", "delete", "list", "edit", "fix" }, flags = { "-g", "--global", "--json" } }),
            "dedupe" .. C.parser({ flags = { "--dry-run", "--prefer-dedupe" } }),
            "deprecate" .. C.parser({ args = packages }),
            "diff" .. C.parser({ flags = { "--diff" .. C.values(packages), "--diff-name-only", "--diff-unified" .. C.values({ "3" }) }, args = packages }),
            "docs" .. C.parser({ args = packages, flags = { "--browser" .. C.values({ "default" }) } }),
            "doctor",
            "exec" .. C.parser({ flags = { "--package" .. C.values(packages), "-c" .. C.values({ "command" }), "--yes", "--no" }, args = packages }),
            "explain" .. C.parser({ args = packages }),
            "fund" .. C.parser({ flags = { "--json", "--browser" .. C.values({ "default" }) } }),
            "help" .. C.parser({ args = { "install", "run-script", "config", "cache", "publish", "version" } }),
            "init" .. C.parser({ flags = { "-y", "--yes", "--scope" .. C.values({ "@scope" }), "--workspace" .. C.values({ "workspace" }) }, args = packages }),
            "install" .. C.parser({ flags = install_flags, args = packages }),
            "install-ci-test" .. C.parser({ flags = install_flags }),
            "link" .. C.parser({ flags = { "-g", "--global" }, args = packages }),
            "login" .. C.parser({ flags = { "--registry" .. C.values({ "https://registry.npmjs.org/" }), "--scope" .. C.values({ "@scope" }) } }),
            "logout" .. C.parser({ flags = { "--registry" .. C.values({ "https://registry.npmjs.org/" }), "--scope" .. C.values({ "@scope" }) } }),
            "ls" .. C.parser({ flags = { "-a", "--all", "--depth" .. C.values({ "0", "1", "2" }), "--json", "-g", "--global", "--long", "--parseable" }, args = packages }),
            "outdated" .. C.parser({ flags = { "--json", "--long", "--parseable", "-g", "--global" }, args = packages }),
            "owner" .. C.parser({ args = { "add", "rm", "ls" } }),
            "pack" .. C.parser({ flags = { "--dry-run", "--json", "--pack-destination" .. C.dir_arg() }, args = packages }),
            "ping" .. C.parser({ flags = { "--registry" .. C.values({ "https://registry.npmjs.org/" }) } }),
            "prefix" .. C.parser({ flags = { "-g", "--global" } }),
            "profile" .. C.parser({ args = { "enable-2fa", "disable-2fa", "get", "set" } }),
            "prune" .. C.parser({ flags = { "--dry-run", "--json", "--omit" .. C.values({ "dev", "optional", "peer" }), "--production" }, args = packages }),
            "publish" .. C.parser({ flags = { "--tag" .. C.values({ "latest", "next", "beta", "canary" }), "--access" .. C.values({ "public", "restricted" }), "--dry-run", "--otp" .. C.values({ "000000" }) }, args = clink.filematches }),
            "rebuild" .. C.parser({ args = packages }),
            "repo" .. C.parser({ args = packages }),
            "restart" .. C.parser({ flags = { "--workspace" .. C.values({ "workspace" }) } }),
            "root" .. C.parser({ flags = { "-g", "--global" } }),
            "run" .. C.parser({ args = scripts, flags = { "--if-present", "--ignore-scripts", "--workspace" .. C.values({ "workspace" }), "--workspaces" } }),
            "run-script" .. C.parser({ args = scripts, flags = { "--if-present", "--ignore-scripts", "--workspace" .. C.values({ "workspace" }), "--workspaces" } }),
            "search" .. C.parser({ flags = { "--json", "--long", "--parseable", "--searchlimit" .. C.values({ "20" }) }, args = packages }),
            "shrinkwrap",
            "star" .. C.parser({ args = packages }),
            "stars" .. C.parser({ args = packages }),
            "start" .. C.parser({ flags = { "--if-present" } }),
            "stop" .. C.parser({ flags = { "--if-present" } }),
            "team" .. C.parser({ args = { "create", "destroy", "add", "rm", "ls", "edit" } }),
            "test" .. C.parser({ flags = { "--if-present", "--workspace" .. C.values({ "workspace" }), "--workspaces" } }),
            "token" .. C.parser({ args = { "list", "revoke", "create" } }),
            "uninstall" .. C.parser({ flags = { "-g", "--global", "-D", "--save-dev", "-P", "--save-prod", "-O", "--save-optional", "--no-save" }, args = packages }),
            "unpublish" .. C.parser({ flags = { "--force", "--dry-run" }, args = packages }),
            "update" .. C.parser({ flags = { "-g", "--global", "--depth" .. C.values({ "0" }) }, args = packages }),
            "version" .. C.parser({ args = { "major", "minor", "patch", "premajor", "preminor", "prepatch", "prerelease", "from-git" }, flags = { "--no-git-tag-version", "--allow-same-version", "-m" .. C.values({ "message" }) } }),
            "view" .. C.parser({ args = packages }),
            "whoami" .. C.parser({ flags = { "--registry" .. C.values({ "https://registry.npmjs.org/" }) } }),
        },
    })
end)

C.register({ "npx", "npx.cmd" }, function(parser)
    C.apply(parser, {
        flags = {
            "-h", "--help", "-v", "--version",
            "-p" .. C.values(packages), "--package" .. C.values(packages),
            "-c" .. C.values({ "command" }), "--call" .. C.values({ "command" }),
            "--yes", "--no", "--shell" .. C.values({ "cmd", "powershell", "bash" }),
        },
        args = packages,
    })
end)

