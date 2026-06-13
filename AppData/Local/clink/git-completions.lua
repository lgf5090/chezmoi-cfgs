--------------------------------------------------------------------------------
-- Static git completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local common_refs = {
    "HEAD", "FETCH_HEAD", "ORIG_HEAD", "MERGE_HEAD",
    "main", "master", "develop", "dev", "staging", "release",
    "origin/main", "origin/master", "origin/develop",
}

local remote_names = { "origin", "upstream" }
local config_scopes = { "--local", "--global", "--system", "--worktree" }

local commit_flags = {
    "-a", "--all", "-m" .. C.values({ "message" }), "--message" .. C.values({ "message" }),
    "--amend", "--no-edit", "--signoff", "--no-verify", "--verbose", "--dry-run",
    "--fixup" .. C.values(common_refs), "--squash" .. C.values(common_refs),
}

local diff_flags = {
    "--cached", "--staged", "--stat", "--name-only", "--name-status",
    "--check", "--color-words", "--word-diff", "--summary", "--patch",
}

local log_flags = {
    "--oneline", "--graph", "--decorate", "--all", "--stat", "--patch",
    "--follow", "--name-only", "--name-status", "--reverse",
    "--since" .. C.values({ "yesterday", "1 week ago", "1 month ago" }),
    "--until" .. C.values({ "yesterday", "1 week ago", "1 month ago" }),
    "--author" .. C.values({ "author" }),
    "--grep" .. C.values({ "pattern" }),
    "--format" .. C.values({ "oneline", "short", "medium", "full", "fuller", "reference" }),
}

local stash_parser = C.parser({
    args = {
        "push" .. C.parser({ flags = { "-m" .. C.values({ "message" }), "--message" .. C.values({ "message" }), "-u", "--include-untracked", "-a", "--all", "--patch" } }),
        "pop" .. C.parser({ args = { "stash@{0}", "stash@{1}", "stash@{2}" } }),
        "apply" .. C.parser({ args = { "stash@{0}", "stash@{1}", "stash@{2}" } }),
        "list",
        "show" .. C.parser({ flags = diff_flags, args = { "stash@{0}", "stash@{1}", "stash@{2}" } }),
        "drop" .. C.parser({ args = { "stash@{0}", "stash@{1}", "stash@{2}" } }),
        "clear",
        "branch" .. C.parser({ args = { "stash@{0}", "stash@{1}", "stash@{2}" } }),
    },
    flags = { "-h", "--help" },
})

local subcommands = {
    "add" .. C.parser({ flags = { "-A", "--all", "-u", "--update", "-p", "--patch", "-n", "--dry-run", "-v", "--verbose" }, args = clink.filematches }),
    "am" .. C.parser({ flags = { "--continue", "--skip", "--abort", "--show-current-patch", "-3", "--3way" }, args = clink.filematches }),
    "archive" .. C.parser({ flags = { "--format" .. C.values({ "tar", "zip" }), "--output" .. C.file_arg(), "--prefix" .. C.values({ "prefix/" }) }, args = common_refs }),
    "bisect" .. C.parser({ args = { "start", "bad", "good", "skip", "reset", "visualize", "replay", "log", "run" } }),
    "blame" .. C.parser({ flags = { "-L" .. C.values({ "start,end" }), "-w", "--show-stats", "--date" .. C.values({ "relative", "local", "iso", "short" }) }, args = clink.filematches }),
    "branch" .. C.parser({ flags = { "-a", "--all", "-r", "--remotes", "-d", "-D", "-m", "-M", "--show-current", "--merged", "--no-merged", "--contains" .. C.values(common_refs) }, args = common_refs }),
    "checkout" .. C.parser({ flags = { "-b" .. C.values({ "branch" }), "-B" .. C.values({ "branch" }), "--detach", "--track", "--orphan" .. C.values({ "branch" }), "--ours", "--theirs", "-p", "--patch" }, args = common_refs }),
    "cherry-pick" .. C.parser({ flags = { "--continue", "--skip", "--abort", "--quit", "-n", "--no-commit", "-x", "--signoff" }, args = common_refs }),
    "clean" .. C.parser({ flags = { "-d", "-f", "-i", "-n", "--dry-run", "-q", "-x", "-X" } }),
    "clone" .. C.parser({ flags = { "--bare", "--mirror", "--depth" .. C.values({ "1" }), "--branch" .. C.values(common_refs), "--recurse-submodules", "--single-branch", "--origin" .. C.values(remote_names) } }),
    "commit" .. C.parser({ flags = commit_flags, args = clink.filematches }),
    "config" .. C.parser({ flags = config_scopes, args = { "user.name", "user.email", "core.editor", "core.autocrlf", "init.defaultBranch", "pull.rebase", "push.default", "alias." } }),
    "describe" .. C.parser({ flags = { "--all", "--tags", "--contains", "--dirty", "--always", "--long", "--abbrev" .. C.values({ "7", "12" }) }, args = common_refs }),
    "diff" .. C.parser({ flags = diff_flags, args = common_refs }),
    "fetch" .. C.parser({ flags = { "--all", "--prune", "--tags", "--dry-run", "--depth" .. C.values({ "1" }), "--recurse-submodules" }, args = remote_names }),
    "grep" .. C.parser({ flags = { "-n", "--line-number", "-i", "--ignore-case", "-w", "--word-regexp", "-E", "--extended-regexp", "-F", "--fixed-strings", "--cached" }, args = { "pattern" } }),
    "init" .. C.parser({ flags = { "--bare", "--initial-branch" .. C.values({ "main", "master" }), "-b" .. C.values({ "main", "master" }), "--separate-git-dir" .. C.dir_arg() } }),
    "log" .. C.parser({ flags = log_flags, args = common_refs }),
    "merge" .. C.parser({ flags = { "--abort", "--continue", "--quit", "--no-ff", "--ff-only", "--squash", "--no-commit", "--strategy" .. C.values({ "ort", "recursive", "resolve", "ours", "octopus", "subtree" }) }, args = common_refs }),
    "mv" .. C.parser({ flags = { "-f", "--force", "-k", "-n", "--dry-run", "-v", "--verbose" }, args = clink.filematches }),
    "pull" .. C.parser({ flags = { "--rebase", "--no-rebase", "--ff-only", "--no-ff", "--autostash", "--prune", "--tags" }, args = remote_names }),
    "push" .. C.parser({ flags = { "-u", "--set-upstream", "--force-with-lease", "--force", "--tags", "--all", "--mirror", "--delete", "--dry-run", "--follow-tags" }, args = remote_names }),
    "rebase" .. C.parser({ flags = { "-i", "--interactive", "--continue", "--skip", "--abort", "--quit", "--onto" .. C.values(common_refs), "--autostash", "--rebase-merges" }, args = common_refs }),
    "remote" .. C.parser({ args = {
        "add" .. C.parser({ args = remote_names }),
        "remove" .. C.parser({ args = remote_names }),
        "rename" .. C.parser({ args = remote_names }),
        "set-url" .. C.parser({ args = remote_names }),
        "show" .. C.parser({ args = remote_names }),
        "prune" .. C.parser({ args = remote_names }),
        "update",
        "-v", "--verbose",
    } }),
    "reset" .. C.parser({ flags = { "--soft", "--mixed", "--hard", "--merge", "--keep", "-p", "--patch" }, args = common_refs }),
    "restore" .. C.parser({ flags = { "--source" .. C.values(common_refs), "--staged", "--worktree", "-p", "--patch" }, args = clink.filematches }),
    "revert" .. C.parser({ flags = { "--continue", "--skip", "--abort", "--quit", "--no-commit", "--edit", "--signoff" }, args = common_refs }),
    "rm" .. C.parser({ flags = { "-r", "--recursive", "-f", "--force", "--cached", "-n", "--dry-run" }, args = clink.filematches }),
    "show" .. C.parser({ flags = diff_flags, args = common_refs }),
    "stash" .. stash_parser,
    "status" .. C.parser({ flags = { "-s", "--short", "-b", "--branch", "--porcelain", "--ignored", "-u" .. C.values({ "no", "normal", "all" }) } }),
    "switch" .. C.parser({ flags = { "-c" .. C.values({ "branch" }), "-C" .. C.values({ "branch" }), "--detach", "--guess", "--track" }, args = common_refs }),
    "tag" .. C.parser({ flags = { "-a", "--annotate", "-d", "--delete", "-f", "--force", "-l", "--list", "-m" .. C.values({ "message" }), "--sort" .. C.values({ "refname", "-creatordate", "version:refname" }) }, args = common_refs }),
    "worktree" .. C.parser({ args = { "add", "list", "lock", "move", "prune", "remove", "repair", "unlock" } }),
}

C.register({ "git", "git.exe" }, function(parser)
    C.apply(parser, {
        flags = {
            "--help", "--version", "--paginate", "--no-pager",
            "-C" .. C.dir_arg(),
            "-c" .. C.values({ "name=value" }),
            "--git-dir" .. C.dir_arg(),
            "--work-tree" .. C.dir_arg(),
            "--namespace" .. C.values({ "namespace" }),
        },
        args = subcommands,
    })
end)

