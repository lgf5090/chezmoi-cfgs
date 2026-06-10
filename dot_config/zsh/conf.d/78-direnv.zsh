if (( $+commands[direnv] )) && [[ -o interactive ]]; then
  __zsh_direnv=${commands[direnv]}
  __zsh_direnv_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  __zsh_direnv_cache_key=${__zsh_direnv:A}
  __zsh_direnv_cache_key=${__zsh_direnv_cache_key//\//%}
  __zsh_direnv_cache="$__zsh_direnv_cache_dir/direnv-hook-${__zsh_direnv_cache_key}.zsh"

  if [[ -s $__zsh_direnv_cache && $__zsh_direnv_cache -nt $__zsh_direnv ]]; then
    source "$__zsh_direnv_cache"
  else
    __zsh_direnv_hook=$("$__zsh_direnv" hook zsh 2>/dev/null || :)
    if [[ -n $__zsh_direnv_hook ]]; then
      eval "$__zsh_direnv_hook"
      if [[ -d $__zsh_direnv_cache_dir || -w ${__zsh_direnv_cache_dir:h} ]]; then
        [[ -d $__zsh_direnv_cache_dir ]] || mkdir -p "$__zsh_direnv_cache_dir" 2>/dev/null
        if [[ -d $__zsh_direnv_cache_dir && -w $__zsh_direnv_cache_dir ]]; then
          __zsh_direnv_cache_tmp="$__zsh_direnv_cache.tmp.$$"
          print -r -- "$__zsh_direnv_hook" > "$__zsh_direnv_cache_tmp" \
            && command mv -f "$__zsh_direnv_cache_tmp" "$__zsh_direnv_cache" 2>/dev/null \
            || command rm -f "$__zsh_direnv_cache_tmp"
        fi
      fi
    fi
  fi
  unset __zsh_direnv __zsh_direnv_hook __zsh_direnv_cache_dir \
    __zsh_direnv_cache_key __zsh_direnv_cache __zsh_direnv_cache_tmp
fi
