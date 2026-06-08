: "${MISE_DATA_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/mise}"
export MISE_DATA_DIR

__zsh_mise=$(command -v mise 2>/dev/null)
if [[ -z $__zsh_mise ]]; then
  for __zsh_mise_candidate in \
    "$HOME/.local/bin/mise" \
    /home/linuxbrew/.linuxbrew/bin/mise \
    "$HOME/.linuxbrew/bin/mise" \
    /opt/homebrew/bin/mise \
    /usr/local/bin/mise \
    /opt/mise/bin/mise
  do
    [[ -x $__zsh_mise_candidate ]] || continue
    __zsh_mise=$__zsh_mise_candidate
    break
  done
  unset __zsh_mise_candidate
fi

if [[ -n $__zsh_mise && -x $__zsh_mise ]]; then
  eval "$("$__zsh_mise" activate zsh)"
fi
unset __zsh_mise

_zpath_prepend "$HOME/.mise/shims" "$MISE_DATA_DIR/shims"
