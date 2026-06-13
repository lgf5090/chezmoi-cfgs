--------------------------------------------------------------------------------
-- Static docker and docker-compose completions for Clink.

local C = shells_completions
if not C or not C.available() then
    return
end

local containers = { "CONTAINER", "container_name" }
local images = { "IMAGE", "image:tag", "ubuntu:latest", "alpine:latest", "node:latest", "python:latest" }
local services = { "SERVICE", "web", "app", "api", "db", "redis", "worker" }
local networks = { "bridge", "host", "none", "NETWORK" }
local volumes = { "VOLUME" }

local common_flags = {
    "--help", "--version", "--config" .. C.dir_arg(), "--context" .. C.values({ "default", "desktop-linux" }),
    "--host" .. C.values({ "tcp://127.0.0.1:2375", "npipe:////./pipe/docker_engine" }),
    "--log-level" .. C.values({ "debug", "info", "warn", "error", "fatal" }),
    "--tls", "--tlscacert" .. C.file_arg(), "--tlscert" .. C.file_arg(), "--tlskey" .. C.file_arg(), "--tlsverify",
}

local run_flags = {
    "-d", "--detach", "-it", "-i", "--interactive", "-t", "--tty", "--rm",
    "--name" .. C.values(containers), "--hostname" .. C.values({ "hostname" }),
    "-p" .. C.values({ "8080:80" }), "--publish" .. C.values({ "8080:80" }),
    "-P", "--publish-all",
    "-v" .. C.values({ "host_path:container_path" }), "--volume" .. C.values({ "host_path:container_path" }),
    "--mount" .. C.values({ "type=bind,source=,target=", "type=volume,source=,target=" }),
    "-e" .. C.values({ "NAME=value" }), "--env" .. C.values({ "NAME=value" }),
    "--env-file" .. C.file_arg(),
    "-w" .. C.values({ "/work" }), "--workdir" .. C.values({ "/work" }),
    "--entrypoint" .. C.values({ "sh", "bash", "cmd" }),
    "--network" .. C.values(networks),
    "--restart" .. C.values({ "no", "on-failure", "always", "unless-stopped" }),
    "--pull" .. C.values({ "always", "missing", "never" }),
    "--platform" .. C.values({ "linux/amd64", "linux/arm64", "windows/amd64" }),
}

local build_flags = {
    "-t" .. C.values({ "name:tag" }), "--tag" .. C.values({ "name:tag" }),
    "-f" .. C.file_arg(), "--file" .. C.file_arg(),
    "--build-arg" .. C.values({ "NAME=value" }),
    "--target" .. C.values({ "stage" }),
    "--platform" .. C.values({ "linux/amd64", "linux/arm64", "windows/amd64" }),
    "--pull", "--no-cache", "--progress" .. C.values({ "auto", "plain", "tty" }),
    "--secret" .. C.values({ "id=,src=" }),
    "--ssh" .. C.values({ "default" }),
}

local compose_flags = {
    "-f" .. C.file_arg(), "--file" .. C.file_arg(),
    "-p" .. C.values({ "project" }), "--project-name" .. C.values({ "project" }),
    "--profile" .. C.values({ "dev", "test", "prod" }),
    "--env-file" .. C.file_arg(),
    "--ansi" .. C.values({ "auto", "never", "always" }),
}

local compose_parser = C.parser({
    flags = compose_flags,
    args = {
        "build" .. C.parser({ flags = build_flags, args = services }),
        "config" .. C.parser({ flags = { "--profiles", "--services", "--volumes", "--quiet", "--format" .. C.values({ "yaml", "json" }) } }),
        "cp" .. C.parser({ args = services }),
        "create" .. C.parser({ flags = { "--build", "--no-build", "--force-recreate", "--no-recreate", "--pull" .. C.values({ "always", "missing", "never" }) }, args = services }),
        "down" .. C.parser({ flags = { "-v", "--volumes", "--remove-orphans", "--rmi" .. C.values({ "all", "local" }), "--timeout" .. C.values({ "10" }) } }),
        "exec" .. C.parser({ flags = { "-d", "--detach", "-e" .. C.values({ "NAME=value" }), "--env" .. C.values({ "NAME=value" }), "-T", "--index" .. C.values({ "1" }), "-u" .. C.values({ "user" }), "--user" .. C.values({ "user" }), "-w" .. C.values({ "/work" }) }, args = services }),
        "images" .. C.parser({ args = services }),
        "kill" .. C.parser({ flags = { "-s" .. C.values({ "SIGTERM", "SIGKILL", "SIGINT" }), "--signal" .. C.values({ "SIGTERM", "SIGKILL", "SIGINT" }) }, args = services }),
        "logs" .. C.parser({ flags = { "-f", "--follow", "--tail" .. C.values({ "100" }), "--since" .. C.values({ "1h" }), "--until" .. C.values({ "1h" }), "-t", "--timestamps", "--no-color" }, args = services }),
        "ls" .. C.parser({ flags = { "-a", "--all", "--format" .. C.values({ "table", "json" }), "-q", "--quiet" } }),
        "pause" .. C.parser({ args = services }),
        "port" .. C.parser({ args = services }),
        "ps" .. C.parser({ flags = { "-a", "--all", "--format" .. C.values({ "table", "json" }), "-q", "--quiet", "--services" }, args = services }),
        "pull" .. C.parser({ flags = { "--ignore-pull-failures", "--include-deps", "--policy" .. C.values({ "always", "missing" }), "-q", "--quiet" }, args = services }),
        "push" .. C.parser({ flags = { "--ignore-push-failures", "-q", "--quiet" }, args = services }),
        "restart" .. C.parser({ flags = { "-t" .. C.values({ "10" }), "--timeout" .. C.values({ "10" }) }, args = services }),
        "rm" .. C.parser({ flags = { "-f", "--force", "-s", "--stop", "-v", "--volumes" }, args = services }),
        "run" .. C.parser({ flags = run_flags, args = services }),
        "start" .. C.parser({ args = services }),
        "stop" .. C.parser({ flags = { "-t" .. C.values({ "10" }), "--timeout" .. C.values({ "10" }) }, args = services }),
        "top" .. C.parser({ args = services }),
        "unpause" .. C.parser({ args = services }),
        "up" .. C.parser({ flags = { "-d", "--detach", "--build", "--no-build", "--force-recreate", "--no-recreate", "--remove-orphans", "--pull" .. C.values({ "always", "missing", "never" }), "--scale" .. C.values({ "SERVICE=NUM" }), "--wait" }, args = services }),
        "version",
    },
})

local docker_subcommands = {
    "build" .. C.parser({ flags = build_flags, args = clink.dirmatches }),
    "builder" .. C.parser({ args = { "build", "create", "du", "inspect", "ls", "prune", "rm", "stop" } }),
    "compose" .. compose_parser,
    "container" .. C.parser({ args = { "attach", "commit", "cp", "create", "diff", "exec", "export", "inspect", "kill", "logs", "ls", "pause", "port", "prune", "rename", "restart", "rm", "run", "start", "stats", "stop", "top", "unpause", "update", "wait" } }),
    "cp" .. C.parser({ args = containers }),
    "create" .. C.parser({ flags = run_flags, args = images }),
    "exec" .. C.parser({ flags = { "-d", "--detach", "-e" .. C.values({ "NAME=value" }), "--env" .. C.values({ "NAME=value" }), "-i", "--interactive", "-t", "--tty", "-u" .. C.values({ "user" }), "--user" .. C.values({ "user" }), "-w" .. C.values({ "/work" }), "--workdir" .. C.values({ "/work" }) }, args = containers }),
    "image" .. C.parser({ args = { "build", "history", "import", "inspect", "load", "ls", "prune", "pull", "push", "rm", "save", "tag" } }),
    "images" .. C.parser({ flags = { "-a", "--all", "--digests", "-f" .. C.values({ "dangling=true", "reference=" }), "--filter" .. C.values({ "dangling=true", "reference=" }), "--format" .. C.values({ "table", "json" }), "--no-trunc", "-q", "--quiet" }, args = images }),
    "inspect" .. C.parser({ flags = { "-f" .. C.values({ "{{json .}}" }), "--format" .. C.values({ "{{json .}}" }), "--type" .. C.values({ "container", "image", "volume", "network" }) }, args = containers }),
    "kill" .. C.parser({ flags = { "-s" .. C.values({ "SIGTERM", "SIGKILL", "SIGINT" }), "--signal" .. C.values({ "SIGTERM", "SIGKILL", "SIGINT" }) }, args = containers }),
    "logs" .. C.parser({ flags = { "-f", "--follow", "--tail" .. C.values({ "100" }), "--since" .. C.values({ "1h" }), "--until" .. C.values({ "1h" }), "-t", "--timestamps", "--details" }, args = containers }),
    "network" .. C.parser({ args = { "connect", "create", "disconnect", "inspect", "ls", "prune", "rm" } }),
    "ps" .. C.parser({ flags = { "-a", "--all", "-q", "--quiet", "--no-trunc", "--size", "--latest", "--last" .. C.values({ "5" }), "-f" .. C.values({ "status=running", "name=", "ancestor=" }), "--filter" .. C.values({ "status=running", "name=", "ancestor=" }), "--format" .. C.values({ "table", "json" }) } }),
    "pull" .. C.parser({ flags = { "-a", "--all-tags", "--platform" .. C.values({ "linux/amd64", "linux/arm64", "windows/amd64" }), "-q", "--quiet" }, args = images }),
    "push" .. C.parser({ flags = { "-a", "--all-tags", "-q", "--quiet" }, args = images }),
    "restart" .. C.parser({ flags = { "-t" .. C.values({ "10" }), "--time" .. C.values({ "10" }) }, args = containers }),
    "rm" .. C.parser({ flags = { "-f", "--force", "-l", "--link", "-v", "--volumes" }, args = containers }),
    "rmi" .. C.parser({ flags = { "-f", "--force", "--no-prune" }, args = images }),
    "run" .. C.parser({ flags = run_flags, args = images }),
    "start" .. C.parser({ flags = { "-a", "--attach", "-i", "--interactive" }, args = containers }),
    "stats" .. C.parser({ flags = { "-a", "--all", "--format" .. C.values({ "table", "json" }), "--no-stream", "--no-trunc" }, args = containers }),
    "stop" .. C.parser({ flags = { "-t" .. C.values({ "10" }), "--time" .. C.values({ "10" }) }, args = containers }),
    "system" .. C.parser({ args = { "df", "events", "info", "prune" } }),
    "tag" .. C.parser({ args = images }),
    "volume" .. C.parser({ args = { "create", "inspect", "ls", "prune", "rm" } }),
}

C.register({ "docker", "docker.exe" }, function(parser)
    C.apply(parser, {
        flags = common_flags,
        args = docker_subcommands,
    })
end)

C.register({ "docker-compose", "docker-compose.exe" }, function(parser)
    C.apply(parser, {
        flags = compose_flags,
        args = compose_parser,
    })
end)

