if [[ -n ${PYENV_ROOT:-} ]]; then
  _zpath_prepend "$PYENV_ROOT/bin"
fi

if (( $+commands[pyenv] )); then
  __zsh_pyenv_init=$(pyenv init - zsh 2>/dev/null || pyenv init - 2>/dev/null || :)
  [[ -n $__zsh_pyenv_init ]] && eval "$__zsh_pyenv_init"
  unset __zsh_pyenv_init

  __zsh_pyenv_virtualenv_init=$(pyenv virtualenv-init - zsh 2>/dev/null || pyenv virtualenv-init - 2>/dev/null || :)
  [[ -n $__zsh_pyenv_virtualenv_init ]] && eval "$__zsh_pyenv_virtualenv_init"
  unset __zsh_pyenv_virtualenv_init
fi
