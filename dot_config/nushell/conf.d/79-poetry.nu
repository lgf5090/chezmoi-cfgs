if (($env.POETRY_HOME? | default "") | is-not-empty) {
    _nu_path_prepend ($env.POETRY_HOME | path join "bin")
}
