def _nu_git_prompt [] {
    if (which git | is-empty) { return "" }

    mut dir = $env.PWD
    loop {
        if ($dir | path join ".git" | path exists) {
            let git_dir = $dir
            let branch = (
                try { ^git -C $git_dir symbolic-ref --short HEAD | str trim }
                catch { try { ^git -C $git_dir rev-parse --short HEAD | str trim } catch { "" } }
            )
            if ($branch | is-empty) { return "" }

            let dirty = (try { ^git -C $git_dir diff-index --quiet HEAD --; "" } catch { "*" })
            return $" (ansi magenta)($branch)($dirty)(ansi reset)"
        }

        let parent = ($dir | path dirname)
        if $parent == $dir { return "" }
        $dir = $parent
    }
}

if ($env.SHELLS_NO_PROMPT? | is-empty) {
    $env.PROMPT_COMMAND = {||
        let rc = ($env.LAST_EXIT_CODE? | default 0)
        let now = (date now | format date "%H:%M:%S")
        let cwd = (
            if ($env.PWD | str starts-with $nu.home-dir) {
                "~" + ($env.PWD | str substring ($nu.home-dir | str length)..)
            } else {
                $env.PWD
            }
        )
        let user = ($env.USER? | default ($env.USERNAME? | default ""))
        let host = (sys host | get hostname)
        let venv = (
            if ($env.VIRTUAL_ENV? | is-not-empty) {
                $" (ansi cyan)\(($env.VIRTUAL_ENV | path basename)\)(ansi reset)"
            } else if (($env.CONDA_DEFAULT_ENV? | default "") not-in ["" "base"]) {
                $" (ansi cyan)\(($env.CONDA_DEFAULT_ENV)\)(ansi reset)"
            } else {
                ""
            }
        )
        let git = (_nu_git_prompt)
        let rc_display = if $rc != 0 { $" (ansi red)[($rc)](ansi reset)" } else { "" }

        $"(ansi grey)[($now)](ansi reset) (ansi green)($user)(ansi white)@($host)(ansi reset) (ansi blue)[($cwd)](ansi reset)($venv)($git)($rc_display)\n"
    }

    $env.PROMPT_INDICATOR = $"(ansi cyan)$(ansi reset) "
    $env.PROMPT_INDICATOR_VI_INSERT = $"(ansi cyan)$(ansi reset) "
    $env.PROMPT_INDICATOR_VI_NORMAL = $"(ansi yellow): (ansi reset)"
    $env.PROMPT_COMMAND_RIGHT = ""
}
