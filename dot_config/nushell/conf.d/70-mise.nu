if (($env.MISE_DATA_DIR? | default "") | is-empty) {
    $env.MISE_DATA_DIR = ($env.XDG_DATA_HOME | path join "mise")
}

_nu_path_prepend ...[
    ($nu.home-dir | path join ".mise" "shims")
    ($env.MISE_DATA_DIR | path join "shims")
]
