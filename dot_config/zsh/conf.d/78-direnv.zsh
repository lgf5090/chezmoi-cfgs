if (( $+commands[direnv] )) && [[ -o interactive ]]; then
  __zsh_direnv_hook=$(direnv hook zsh 2>/dev/null || :)
  [[ -n $__zsh_direnv_hook ]] && eval "$__zsh_direnv_hook"
  unset __zsh_direnv_hook
fi
