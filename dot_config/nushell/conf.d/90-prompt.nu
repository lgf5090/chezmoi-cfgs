let nu_prompt_has_git = (which git | is-not-empty)
let nu_prompt_host = (
    if (($env.HOSTNAME? | default "") | is-not-empty) {
        $env.HOSTNAME
    } else if (($env.COMPUTERNAME? | default "") | is-not-empty) {
        $env.COMPUTERNAME
    } else {
        sys host | get hostname
    }
)

def _nu_git_prompt [] {
    if not $nu_prompt_has_git { return "" }

    mut dir = $env.PWD
    loop {
        let git_marker = ($dir | path join ".git")
        let git_marker_type = ($git_marker | path type)
        let git_marker_valid = (
            ($git_marker_type == "file") or (
                ($git_marker_type == "dir") and (($git_marker | path join "HEAD" | path exists))
            )
        )

        if $git_marker_valid {
            let git_dir = $dir
            mut branch = (_nu_git_stdout $git_dir symbolic-ref --short HEAD)
            if ($branch | is-empty) {
                $branch = (_nu_git_stdout $git_dir rev-parse --short HEAD)
            }
            if ($branch | is-empty) { return "" }

            let dirty_result = (^git -C $git_dir diff-index --quiet HEAD -- | complete)
            let dirty = if $dirty_result.exit_code == 0 { "" } else { "*" }
            return $" (ansi magenta)($branch)($dirty)(ansi reset)"
        }

        let parent = ($dir | path dirname)
        if $parent == $dir { return "" }
        $dir = $parent
    }
}

def --wrapped _nu_git_stdout [git_dir: string, ...args: string] {
    let result = (^git -C $git_dir ...$args | complete)
    if $result.exit_code == 0 {
        $result.stdout | str trim
    } else {
        ""
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

        $"(ansi grey)[($now)](ansi reset) (ansi green)($user)(ansi white)@($nu_prompt_host)(ansi reset) (ansi blue)[($cwd)](ansi reset)($venv)($git)($rc_display)\n"
    }

    $env.PROMPT_INDICATOR = $"(ansi cyan)$(ansi reset) "
    $env.PROMPT_INDICATOR_VI_INSERT = $"(ansi cyan)$(ansi reset) "
    $env.PROMPT_INDICATOR_VI_NORMAL = $"(ansi yellow): (ansi reset)"
    $env.PROMPT_COMMAND_RIGHT = ""
}
