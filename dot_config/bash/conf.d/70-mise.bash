: "${MISE_DATA_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/mise}"
export MISE_DATA_DIR

__bash_mise=$(command -v mise 2>/dev/null)
if [[ -z $__bash_mise ]]; then
  for __bash_mise_candidate in \
    "$HOME/.local/bin/mise" \
    /home/linuxbrew/.linuxbrew/bin/mise \
    "$HOME/.linuxbrew/bin/mise" \
    /opt/homebrew/bin/mise \
    /usr/local/bin/mise \
    /opt/mise/bin/mise
  do
    [[ -x $__bash_mise_candidate ]] || continue
    __bash_mise=$__bash_mise_candidate
    break
  done
  unset __bash_mise_candidate
fi

if [[ -n $__bash_mise && -x $__bash_mise ]]; then
  eval "$("$__bash_mise" activate bash)"
fi
unset __bash_mise

_bpath_prepend "$HOME/.mise/shims" "$MISE_DATA_DIR/shims"
