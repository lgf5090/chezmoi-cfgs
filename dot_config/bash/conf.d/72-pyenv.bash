if [[ -n ${PYENV_ROOT:-} ]]; then
  _bpath_prepend "$PYENV_ROOT/bin"
fi

if command -v pyenv >/dev/null 2>&1; then
  __bash_pyenv_init=$(pyenv init - bash 2>/dev/null || pyenv init - 2>/dev/null || :)
  [[ -n $__bash_pyenv_init ]] && eval "$__bash_pyenv_init"
  unset __bash_pyenv_init

  __bash_pyenv_virtualenv_init=$(pyenv virtualenv-init - bash 2>/dev/null || pyenv virtualenv-init - 2>/dev/null || :)
  [[ -n $__bash_pyenv_virtualenv_init ]] && eval "$__bash_pyenv_virtualenv_init"
  unset __bash_pyenv_virtualenv_init
fi
