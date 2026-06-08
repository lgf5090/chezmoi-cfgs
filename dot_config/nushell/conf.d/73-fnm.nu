if (($env.FNM_DIR? | default "") | is-not-empty) {
    _nu_path_prepend $env.FNM_DIR
}
