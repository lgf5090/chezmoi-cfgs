--------------------------------------------------------------------------------
-- Static cargo/rustup completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local packages = { "PACKAGE", "crate", "workspace_member" }
local targets = { "x86_64-pc-windows-msvc", "x86_64-pc-windows-gnu", "x86_64-unknown-linux-gnu", "aarch64-unknown-linux-gnu" }
local profiles = { "dev", "release", "test", "bench" }

local cargo_common_flags = {
    "-h", "--help", "-V", "--version", "-v", "--verbose", "-q", "--quiet",
    "--color" .. C.values({ "auto", "always", "never" }),
    "--config" .. C.values({ "key=value" }),
    "-Z" .. C.values({ "unstable-options" }),
}

local manifest_flags = {
    "--manifest-path" .. C.file_arg(),
    "--locked", "--offline", "--frozen",
    "--target-dir" .. C.dir_arg(),
}

local package_flags = {
    "-p" .. C.values(packages), "--package" .. C.values(packages),
    "--workspace", "--all", "--exclude" .. C.values(packages),
}

local build_flags = {
    "--bin" .. C.values({ "name" }), "--bins",
    "--example" .. C.values({ "name" }), "--examples",
    "--test" .. C.values({ "name" }), "--tests",
    "--bench" .. C.values({ "name" }), "--benches",
    "--all-targets", "--release",
    "--profile" .. C.values(profiles),
    "--target" .. C.values(targets),
    "--features" .. C.values({ "feature1,feature2" }),
    "--all-features", "--no-default-features",
    "-j" .. C.values({ "4" }), "--jobs" .. C.values({ "4" }),
    "--keep-going",
}
for _, flag in ipairs(manifest_flags) do
    build_flags[#build_flags + 1] = flag
end
for _, flag in ipairs(package_flags) do
    build_flags[#build_flags + 1] = flag
end

C.register({ "cargo", "cargo.exe" }, function(parser)
    C.apply(parser, {
        flags = cargo_common_flags,
        args = {
            "add" .. C.parser({ flags = { "--dev", "--build", "--optional", "--no-default-features", "--default-features", "--features" .. C.values({ "feature" }), "--git" .. C.values({ "url" }), "--branch" .. C.values({ "branch" }), "--tag" .. C.values({ "tag" }), "--rev" .. C.values({ "rev" }), "--path" .. C.dir_arg(), "--registry" .. C.values({ "registry" }) }, args = packages }),
            "bench" .. C.parser({ flags = build_flags, args = packages }),
            "build" .. C.parser({ flags = build_flags, args = packages }),
            "check" .. C.parser({ flags = build_flags, args = packages }),
            "clean" .. C.parser({ flags = { "-p" .. C.values(packages), "--package" .. C.values(packages), "--target" .. C.values(targets), "--target-dir" .. C.dir_arg(), "--release", "--profile" .. C.values(profiles), "--doc" } }),
            "clippy" .. C.parser({ flags = build_flags, args = packages }),
            "doc" .. C.parser({ flags = { "--open", "--no-deps", "--document-private-items" }, args = packages }),
            "fetch" .. C.parser({ flags = manifest_flags }),
            "fix" .. C.parser({ flags = { "--allow-dirty", "--allow-staged", "--broken-code", "--edition" }, args = packages }),
            "fmt" .. C.parser({ flags = { "--all", "--check", "--manifest-path" .. C.file_arg() } }),
            "generate-lockfile" .. C.parser({ flags = manifest_flags }),
            "help" .. C.parser({ args = { "build", "check", "clean", "doc", "fetch", "install", "new", "run", "test", "update" } }),
            "init" .. C.parser({ flags = { "--bin", "--lib", "--edition" .. C.values({ "2021", "2024" }), "--name" .. C.values({ "name" }), "--vcs" .. C.values({ "git", "none" }) }, args = clink.dirmatches }),
            "install" .. C.parser({ flags = { "--version" .. C.values({ "version" }), "--git" .. C.values({ "url" }), "--branch" .. C.values({ "branch" }), "--tag" .. C.values({ "tag" }), "--rev" .. C.values({ "rev" }), "--path" .. C.dir_arg(), "--root" .. C.dir_arg(), "--bin" .. C.values({ "name" }), "--example" .. C.values({ "name" }), "--force", "--locked" }, args = packages }),
            "locate-project" .. C.parser({ flags = { "--workspace", "--message-format" .. C.values({ "plain", "json" }) } }),
            "login" .. C.parser({ flags = { "--registry" .. C.values({ "registry" }) }, args = { "token" } }),
            "logout" .. C.parser({ flags = { "--registry" .. C.values({ "registry" }) } }),
            "metadata" .. C.parser({ flags = { "--format-version" .. C.values({ "1" }), "--no-deps", "--all-features", "--no-default-features", "--features" .. C.values({ "feature" }), "--filter-platform" .. C.values(targets) } }),
            "new" .. C.parser({ flags = { "--bin", "--lib", "--edition" .. C.values({ "2021", "2024" }), "--name" .. C.values({ "name" }), "--vcs" .. C.values({ "git", "none" }) }, args = clink.dirmatches }),
            "owner" .. C.parser({ args = { "--add", "--remove", "--list" } }),
            "package" .. C.parser({ flags = { "--list", "--no-verify", "--no-metadata", "--allow-dirty" }, args = packages }),
            "pkgid" .. C.parser({ flags = manifest_flags, args = packages }),
            "publish" .. C.parser({ flags = { "--dry-run", "--no-verify", "--allow-dirty", "--token" .. C.values({ "token" }), "--registry" .. C.values({ "registry" }) }, args = packages }),
            "remove" .. C.parser({ flags = { "--dev", "--build", "--target" .. C.values(targets) }, args = packages }),
            "report" .. C.parser({ args = { "future-incompatibilities" } }),
            "run" .. C.parser({ flags = build_flags, args = packages }),
            "rustc" .. C.parser({ flags = build_flags, args = packages }),
            "rustdoc" .. C.parser({ flags = build_flags, args = packages }),
            "search" .. C.parser({ flags = { "--limit" .. C.values({ "10" }), "--index" .. C.values({ "url" }), "--registry" .. C.values({ "registry" }) }, args = packages }),
            "test" .. C.parser({ flags = build_flags, args = packages }),
            "tree" .. C.parser({ flags = { "-e" .. C.values({ "features", "normal", "build", "dev" }), "--edges" .. C.values({ "features", "normal", "build", "dev" }), "-i" .. C.values(packages), "--invert" .. C.values(packages), "--depth" .. C.values({ "1" }), "--prefix" .. C.values({ "indent", "depth", "none" }) }, args = packages }),
            "uninstall" .. C.parser({ flags = { "-p" .. C.values(packages), "--package" .. C.values(packages), "--bin" .. C.values({ "name" }), "--root" .. C.dir_arg() }, args = packages }),
            "update" .. C.parser({ flags = { "-p" .. C.values(packages), "--package" .. C.values(packages), "--precise" .. C.values({ "version" }), "--aggressive", "--dry-run", "--workspace" }, args = packages }),
            "vendor" .. C.parser({ flags = { "--sync" .. C.file_arg(), "--versioned-dirs", "--no-delete", "--respect-source-config" }, args = clink.dirmatches }),
            "verify-project" .. C.parser({ flags = manifest_flags }),
            "version",
            "yank" .. C.parser({ flags = { "--vers" .. C.values({ "version" }), "--undo", "--token" .. C.values({ "token" }), "--registry" .. C.values({ "registry" }) }, args = packages }),
        },
    })
end)

C.register({ "rustup", "rustup.exe" }, function(parser)
    C.apply(parser, {
        flags = { "-h", "--help", "-V", "--version", "-v", "--verbose", "-q", "--quiet" },
        args = {
            "show" .. C.parser({ args = { "active-toolchain", "home", "profile" } }),
            "update" .. C.parser({ args = { "stable", "beta", "nightly" } }),
            "check" .. C.parser({ args = { "stable", "beta", "nightly" } }),
            "default" .. C.parser({ args = { "stable", "beta", "nightly" } }),
            "toolchain" .. C.parser({ args = { "install", "uninstall", "list", "link" } }),
            "target" .. C.parser({ args = { "add", "remove", "list" } }),
            "component" .. C.parser({ args = { "add", "remove", "list" } }),
            "override" .. C.parser({ args = { "set", "unset", "list" } }),
            "run" .. C.parser({ args = { "stable", "beta", "nightly" } }),
            "which" .. C.parser({ args = { "rustc", "cargo", "rustfmt", "clippy-driver" } }),
            "doc" .. C.parser({ flags = { "--book", "--std", "--reference", "--nomicon", "--path" .. C.values({ "path" }) } }),
            "self" .. C.parser({ args = { "update", "uninstall" } }),
        },
    })
end)

