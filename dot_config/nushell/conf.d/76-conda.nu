_nu_path_prepend ...[
    (if (($env.ANACONDA_HOME? | default "") | is-empty) { "" } else { $env.ANACONDA_HOME | path join "bin" })
    (if (($env.ANACONDA_HOME? | default "") | is-empty) { "" } else { $env.ANACONDA_HOME | path join "condabin" })
]

if (which micromamba | is-not-empty) {
    let micromamba_root = ($nu.home-dir | path join ".local" "share" "micromamba")
    if (($env.MAMBA_ROOT_PREFIX? | default "") | is-empty) and ($micromamba_root | path exists) {
        $env.MAMBA_ROOT_PREFIX = $micromamba_root
    }
}
