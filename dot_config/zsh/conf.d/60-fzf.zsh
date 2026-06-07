if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'
else
  export FZF_DEFAULT_COMMAND='find . -type f'
fi

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border=rounded --preview-window=right:65%:wrap:border-left'

if (( $+commands[bat] )); then
  export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
else
  export _FZF_PREVIEW_CMD='sed -n "1,200p" {} 2>/dev/null'
fi
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

if (( $+commands[fzf] )) && [[ -o interactive && -t 0 && -t 1 ]]; then
  _fzf_ver=$(fzf --version 2>/dev/null | awk '{print $1}')

  if _zver_ge "$_fzf_ver" "0.48.0"; then
    source <(fzf --zsh)
  else
    _fzf_dirs=(/usr/share/fzf /usr/share/doc/fzf/examples)
    if (( $+commands[brew] )); then
      _fzf_brew=$(brew --prefix fzf 2>/dev/null)
      [[ -n $_fzf_brew ]] && _fzf_dirs=("$_fzf_brew/shell" "${_fzf_dirs[@]}")
      unset _fzf_brew
    fi

    for _fzf_dir in "${_fzf_dirs[@]}"; do
      [[ -d $_fzf_dir ]] || continue
      source "$_fzf_dir/key-bindings.zsh" 2>/dev/null
      source "$_fzf_dir/completion.zsh" 2>/dev/null
      break
    done
    unset _fzf_dirs _fzf_dir
  fi
  unset _fzf_ver

  _fzf_file_no_hidden() {
    local result
    if (( $+commands[fd] )); then
      result=$(fd --type f --strip-cwd-prefix | fzf --preview "$_FZF_PREVIEW_CMD")
    else
      result=$(find . -type f ! -path '*/.*' | sed 's#^\./##' | fzf --preview "$_FZF_PREVIEW_CMD")
    fi
    [[ -n $result ]] && LBUFFER+="$result"
    zle reset-prompt
  }
  zle -N _fzf_file_no_hidden
fi
