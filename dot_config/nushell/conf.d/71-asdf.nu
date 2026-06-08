_nu_path_prepend ...[
    (if (($env.ASDF_DIR? | default "") | is-empty) { "" } else { $env.ASDF_DIR | path join "bin" })
    (if (($env.ASDF_DATA_DIR? | default "") | is-empty) { "" } else { $env.ASDF_DATA_DIR | path join "shims" })
]
