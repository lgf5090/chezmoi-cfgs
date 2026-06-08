if command -v direnv >/dev/null 2>&1 && [[ $- == *i* ]]; then
  __bash_direnv_hook=$(direnv hook bash 2>/dev/null || :)
  [[ -n $__bash_direnv_hook ]] && eval "$__bash_direnv_hook"
  unset __bash_direnv_hook
fi
