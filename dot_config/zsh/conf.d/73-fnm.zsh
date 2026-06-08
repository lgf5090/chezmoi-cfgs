if [[ -n ${FNM_DIR:-} ]]; then
  _zpath_prepend "$FNM_DIR"
fi

if (( $+commands[fnm] )); then
  __zsh_fnm_env=$(fnm env --use-on-cd --shell zsh 2>/dev/null || :)
  [[ -n $__zsh_fnm_env ]] && eval "$__zsh_fnm_env"
  unset __zsh_fnm_env
fi
