for __bash_env_manager in rbenv nodenv goenv; do
  if command -v "$__bash_env_manager" >/dev/null 2>&1; then
    __bash_env_manager_init=$("$__bash_env_manager" init - bash 2>/dev/null || "$__bash_env_manager" init - 2>/dev/null || :)
    [[ -n $__bash_env_manager_init ]] && eval "$__bash_env_manager_init"
    unset __bash_env_manager_init
  fi
done
unset __bash_env_manager

if command -v jenv >/dev/null 2>&1; then
  __bash_jenv_init=$(jenv init - 2>/dev/null || :)
  [[ -n $__bash_jenv_init ]] && eval "$__bash_jenv_init"
  unset __bash_jenv_init
fi
