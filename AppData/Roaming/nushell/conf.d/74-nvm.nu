if (($env.NVM_DIR? | default "") | is-empty) {
    $env.NVM_DIR = ($nu.home-dir | path join ".nvm")
}

if $env.SHELLS_OS == "windows" {
    if (($env.NVM_HOME? | default "") | is-empty) {
        for dir in [
            (if (($env.APPDATA? | default "") | is-empty) { "" } else { $env.APPDATA | path join "nvm" })
            ($nu.home-dir | path join "scoop" "apps" "nvm" "current")
            ($nu.home-dir | path join ".nvm")
        ] {
            if ($dir | is-empty) { continue }
            if ($dir | path exists) and (($dir | path type) == "dir") {
                $env.NVM_HOME = $dir
                break
            }
        }
    }

    if (($env.NVM_SYMLINK? | default "") | is-empty) {
        for dir in [
            (if (($env.ProgramFiles? | default "") | is-empty) { "" } else { $env.ProgramFiles | path join "nodejs" })
            ($nu.home-dir | path join "scoop" "apps" "nodejs" "current")
        ] {
            if ($dir | is-empty) { continue }
            if ($dir | path exists) and (($dir | path type) == "dir") {
                $env.NVM_SYMLINK = $dir
                break
            }
        }
    }
}

_nu_path_prepend ...[
    ($env.NVM_HOME? | default "")
    ($env.NVM_SYMLINK? | default "")
]
