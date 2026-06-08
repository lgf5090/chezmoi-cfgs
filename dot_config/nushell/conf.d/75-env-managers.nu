_nu_path_prepend ...[
    (if (($env.RBENV_ROOT? | default "") | is-empty) { "" } else { $env.RBENV_ROOT | path join "bin" })
    (if (($env.RBENV_ROOT? | default "") | is-empty) { "" } else { $env.RBENV_ROOT | path join "shims" })
    (if (($env.NODENV_ROOT? | default "") | is-empty) { "" } else { $env.NODENV_ROOT | path join "bin" })
    (if (($env.NODENV_ROOT? | default "") | is-empty) { "" } else { $env.NODENV_ROOT | path join "shims" })
    (if (($env.GOENV_ROOT? | default "") | is-empty) { "" } else { $env.GOENV_ROOT | path join "bin" })
    (if (($env.GOENV_ROOT? | default "") | is-empty) { "" } else { $env.GOENV_ROOT | path join "shims" })
    (if (($env.JENV_ROOT? | default "") | is-empty) { "" } else { $env.JENV_ROOT | path join "bin" })
    (if (($env.JENV_ROOT? | default "") | is-empty) { "" } else { $env.JENV_ROOT | path join "shims" })
]
