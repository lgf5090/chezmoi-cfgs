if (which micromamba | is-not-empty) {
    let micromamba_root = ($nu.home-dir | path join ".local" "share" "micromamba")
    if (($env.MAMBA_ROOT_PREFIX? | default "") | is-empty) and ($micromamba_root | path exists) {
        $env.MAMBA_ROOT_PREFIX = $micromamba_root
    }
}
