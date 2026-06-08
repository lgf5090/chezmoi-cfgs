def --env _nu_direnv_export [] {
    if (which direnv | is-empty) { return }

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

if (which direnv | is-not-empty) {
    let pwd_hooks = ($env.config.hooks.env_change.PWD? | default [])
    $env.config.hooks.env_change.PWD = (
        $pwd_hooks | append { |before, after| _nu_direnv_export }
    )
    _nu_direnv_export
}
