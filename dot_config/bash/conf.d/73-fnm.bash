if [[ -n ${FNM_DIR:-} ]]; then
  _bpath_prepend "$FNM_DIR"
fi

if command -v fnm >/dev/null 2>&1; then
  __bash_fnm_env=$(fnm env --use-on-cd --shell bash 2>/dev/null || :)
  [[ -n $__bash_fnm_env ]] && eval "$__bash_fnm_env"
  unset __bash_fnm_env
fi
