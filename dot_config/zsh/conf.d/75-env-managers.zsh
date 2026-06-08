for __zsh_env_manager in rbenv nodenv goenv; do
  if (( $+commands[$__zsh_env_manager] )); then
    __zsh_env_manager_init=$("$__zsh_env_manager" init - zsh 2>/dev/null || "$__zsh_env_manager" init - 2>/dev/null || :)
    [[ -n $__zsh_env_manager_init ]] && eval "$__zsh_env_manager_init"
    unset __zsh_env_manager_init
  fi
done
unset __zsh_env_manager

if (( $+commands[jenv] )); then
  __zsh_jenv_init=$(jenv init - 2>/dev/null || :)
  [[ -n $__zsh_jenv_init ]] && eval "$__zsh_jenv_init"
  unset __zsh_jenv_init
fi
