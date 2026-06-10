def --env _nu_direnv_export [] {
    let result = (^direnv export json | complete)
    if $result.exit_code != 0 { return }
    if ($result.stdout | str trim | is-empty) { return }

    let changes = ($result.stdout | from json)
    for item in ($changes | transpose name value) {
        if $item.value == null {
            hide-env $item.name
        } else if $item.name == "PATH" {
            $env.PATH = ($item.value | split row (char path_sep))
        } else {
            load-env { ($item.name): $item.value }
        }
    }
}

def _nu_direnv_should_export [] {
    if (($env.DIRENV_FILE? | default "") | is-not-empty) { return true }

    mut dir = $env.PWD
    loop {
        if (($dir | path join ".envrc") | path exists) { return true }

        let parent = ($dir | path dirname)
        if $parent == $dir { return false }
        $dir = $parent
    }
}

let nu_direnv_available = (which direnv | is-not-empty)
if $nu_direnv_available {
    let pwd_hooks = ($env.config.hooks.env_change.PWD? | default [])
    $env.config.hooks.env_change.PWD = (
        $pwd_hooks | append { |before, after| _nu_direnv_export }
    )
    if (_nu_direnv_should_export) {
        _nu_direnv_export
    }
}
