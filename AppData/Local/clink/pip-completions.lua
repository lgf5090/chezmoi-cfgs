--------------------------------------------------------------------------------
-- Static pip completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local packages = { "PACKAGE", "pip", "setuptools", "wheel", "requests", "numpy", "pandas", "pytest", "black", "ruff" }
local formats = { "columns", "freeze", "json" }

local global_flags = {
    "-h", "--help", "--debug", "--isolated", "--require-virtualenv", "--python" .. C.values({ "python", "python3" }),
    "-v", "--verbose", "-q", "--quiet", "--log" .. C.file_arg(),
    "--proxy" .. C.values({ "http://127.0.0.1:3067" }),
    "--retries" .. C.values({ "5" }),
    "--timeout" .. C.values({ "15" }),
    "--exists-action" .. C.values({ "s", "i", "w", "b", "a" }),
    "--trusted-host" .. C.values({ "pypi.org", "files.pythonhosted.org" }),
    "--cert" .. C.file_arg(), "--client-cert" .. C.file_arg(),
    "--cache-dir" .. C.dir_arg(), "--no-cache-dir",
    "--disable-pip-version-check", "--no-color",
}

local index_flags = {
    "-i" .. C.values({ "https://pypi.org/simple" }), "--index-url" .. C.values({ "https://pypi.org/simple" }),
    "--extra-index-url" .. C.values({ "https://pypi.org/simple" }),
    "--no-index", "-f" .. C.values({ "URL_or_path" }), "--find-links" .. C.values({ "URL_or_path" }),
}

local install_flags = {
    "-r" .. C.file_arg(), "--requirement" .. C.file_arg(),
    "-c" .. C.file_arg(), "--constraint" .. C.file_arg(),
    "-e" .. C.values({ "." }), "--editable" .. C.values({ "." }),
    "-t" .. C.dir_arg(), "--target" .. C.dir_arg(),
    "--user", "--root" .. C.dir_arg(), "--prefix" .. C.dir_arg(),
    "--upgrade", "-U", "--upgrade-strategy" .. C.values({ "only-if-needed", "eager" }),
    "--force-reinstall", "--ignore-installed", "--ignore-requires-python",
    "--no-deps", "--pre", "--dry-run",
    "--only-binary" .. C.values({ ":all:" }),
    "--no-binary" .. C.values({ ":all:" }),
    "--prefer-binary",
    "--require-hashes",
    "--progress-bar" .. C.values({ "on", "off", "raw" }),
    "--root-user-action" .. C.values({ "warn", "ignore" }),
}
for _, flag in ipairs(index_flags) do
    install_flags[#install_flags + 1] = flag
end

C.register({ "pip", "pip3", "pip.exe", "pip3.exe" }, function(parser)
    C.apply(parser, {
        flags = global_flags,
        args = {
            "cache" .. C.parser({ args = { "dir", "info", "list", "remove", "purge" }, flags = { "--format" .. C.values({ "human", "abspath" }) } }),
            "check",
            "completion" .. C.parser({ flags = { "--bash", "--zsh", "--fish", "--powershell" } }),
            "config" .. C.parser({ args = { "debug", "edit", "get", "list", "set", "unset" }, flags = { "--global", "--user", "--site" } }),
            "debug" .. C.parser({ flags = { "--verbose" } }),
            "download" .. C.parser({ flags = install_flags, args = packages }),
            "freeze" .. C.parser({ flags = { "-r" .. C.file_arg(), "--requirement" .. C.file_arg(), "--all", "--exclude-editable", "--path" .. C.dir_arg(), "--exclude" .. C.values(packages) } }),
            "hash" .. C.parser({ flags = { "-a" .. C.values({ "sha256", "sha384", "sha512" }), "--algorithm" .. C.values({ "sha256", "sha384", "sha512" }) }, args = clink.filematches }),
            "help" .. C.parser({ args = { "install", "download", "uninstall", "freeze", "list", "show", "wheel", "config", "cache" } }),
            "index" .. C.parser({ args = { "versions" }, flags = index_flags }),
            "inspect" .. C.parser({ flags = { "--local", "--user", "--path" .. C.dir_arg() } }),
            "install" .. C.parser({ flags = install_flags, args = packages }),
            "list" .. C.parser({ flags = { "--outdated", "--uptodate", "--editable", "--local", "--user", "--path" .. C.dir_arg(), "--pre", "--format" .. C.values(formats), "--not-required", "--exclude-editable", "--include-editable" } }),
            "search" .. C.parser({ args = packages, flags = index_flags }),
            "show" .. C.parser({ flags = { "-f", "--files", "--verbose" }, args = packages }),
            "uninstall" .. C.parser({ flags = { "-r" .. C.file_arg(), "--requirement" .. C.file_arg(), "-y", "--yes", "--root-user-action" .. C.values({ "warn", "ignore" }) }, args = packages }),
            "wheel" .. C.parser({ flags = install_flags, args = packages }),
        },
    })
end)

