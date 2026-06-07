if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'
else
  export FZF_DEFAULT_COMMAND='find . -type f'
fi

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border=rounded --preview-window=right:65%:wrap:border-left'

if command -v bat >/dev/null 2>&1; then
  export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
else
  export _FZF_PREVIEW_CMD='sed -n "1,200p" {} 2>/dev/null'
fi
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

if command -v fzf >/dev/null 2>&1 && [[ $- == *i* && -t 0 && -t 1 ]]; then
  _fzf_ver=$(fzf --version 2>/dev/null | awk '{print $1}')

  if _bver_ge "$_fzf_ver" "0.48.0"; then
    eval "$(fzf --bash)"
  else
    _fzf_dirs=(/usr/share/fzf /usr/share/doc/fzf/examples)
    if command -v brew >/dev/null 2>&1; then
      _fzf_brew=$(brew --prefix fzf 2>/dev/null)
      [[ -n $_fzf_brew ]] && _fzf_dirs=("$_fzf_brew/shell" "${_fzf_dirs[@]}")
      unset _fzf_brew
    fi

    for _fzf_dir in "${_fzf_dirs[@]}"; do
      [[ -d $_fzf_dir ]] || continue
      [[ -r "$_fzf_dir/key-bindings.bash" ]] && source "$_fzf_dir/key-bindings.bash"
      [[ -r "$_fzf_dir/completion.bash" ]] && source "$_fzf_dir/completion.bash"
      break
    done
    unset _fzf_dirs _fzf_dir
  fi
  unset _fzf_ver

  _fzf_file_no_hidden() {
    local result
    if command -v fd >/dev/null 2>&1; then
      result=$(fd --type f --strip-cwd-prefix | fzf --preview "$_FZF_PREVIEW_CMD")
    else
      result=$(find . -type f ! -path '*/.*' | sed 's#^\./##' | fzf --preview "$_FZF_PREVIEW_CMD")
    fi
    [[ -z $result ]] && return 0

    READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}$result${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$(( READLINE_POINT + ${#result} ))
  }

  bind -x '"\C-f": _fzf_file_no_hidden'
fi
