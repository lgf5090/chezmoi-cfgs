if (which zoxide | is-not-empty) {
    def --env z [...query: string] {
        if ($query | is-empty) {
            cd $nu.home-dir
            return
        }

        let dir = (^zoxide query ...$query | str trim)
        if ($dir | is-not-empty) {
            cd $dir
        }
    }

    let pwd_hooks = ($env.config.hooks.env_change.PWD? | default [])
    $env.config.hooks.env_change.PWD = (
        $pwd_hooks | append { |before, after| ^zoxide add $after }
    )
}
