if ($env.EDITOR? | is-empty) { $env.EDITOR = "vim" }
if ($env.VISUAL? | is-empty) { $env.VISUAL = $env.EDITOR }
if ($env.PAGER? | is-empty) { $env.PAGER = "less" }
if ($env.LESS? | is-empty) { $env.LESS = "-R -F -X" }
if ($env.CLICOLOR? | is-empty) { $env.CLICOLOR = "1" }

if $env.SHELLS_OS == "windows" {
    if ($env.MSYS? | is-empty) { $env.MSYS = "winsymlinks:nativestrict" }
}
