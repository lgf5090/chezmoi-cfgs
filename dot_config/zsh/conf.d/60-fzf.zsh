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
  _fzf_dirs=(
    "${commands[fzf]:A:h:h}/shell"
    "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/fzf/shell}"
    /home/linuxbrew/.linuxbrew/opt/fzf/shell
    /opt/homebrew/opt/fzf/shell
    /usr/local/opt/fzf/shell
    /usr/share/fzf
    /usr/share/doc/fzf/examples
  )

  for _fzf_dir in "${_fzf_dirs[@]}"; do
    [[ -r $_fzf_dir/key-bindings.zsh || -r $_fzf_dir/completion.zsh ]] || continue
    source "$_fzf_dir/key-bindings.zsh" 2>/dev/null
    source "$_fzf_dir/completion.zsh" 2>/dev/null
    _fzf_loaded=1
    break
  done

  if [[ -z ${_fzf_loaded:-} ]]; then
    _fzf_ver=${$(fzf --version 2>/dev/null)%% *}
    if _zver_ge "$_fzf_ver" "0.48.0"; then
      source <(fzf --zsh)
    fi
  fi
  unset _fzf_dirs _fzf_dir _fzf_loaded _fzf_ver

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
