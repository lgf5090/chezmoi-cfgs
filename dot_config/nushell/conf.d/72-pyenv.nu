if (($env.PYENV_ROOT? | default "") | is-empty) {
    for dir in [
        ($nu.home-dir | path join ".pyenv" "pyenv-win")
        ($nu.home-dir | path join ".pyenv")
    ] {
        if ($dir | path exists) and (($dir | path type) == "dir") {
            $env.PYENV_ROOT = $dir
            break
        }
    }
}

_nu_path_prepend ...[
    (if (($env.PYENV_ROOT? | default "") | is-empty) { "" } else { $env.PYENV_ROOT | path join "bin" })
    (if (($env.PYENV_ROOT? | default "") | is-empty) { "" } else { $env.PYENV_ROOT | path join "shims" })
    (if (($env.PYENV_ROOT? | default "") | is-empty) { "" } else { $env.PYENV_ROOT | path join "pyenv-win" "bin" })
    (if (($env.PYENV_ROOT? | default "") | is-empty) { "" } else { $env.PYENV_ROOT | path join "pyenv-win" "shims" })
]
