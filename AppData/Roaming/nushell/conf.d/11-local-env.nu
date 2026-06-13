let local_env_file = if ($env.NUSHELL_LOCAL_ENVS_FILE? | is-empty) {
    $nu.home-dir | path join ".envs"
} else {
    $env.NUSHELL_LOCAL_ENVS_FILE
}

_nu_load_envs $local_env_file
