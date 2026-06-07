_zpath_append \
  "$HOME/.local/bin" \
  "$HOME/bin" \
  "$HOME/Applications"

_zpath_prepend \
  "$HOME/.cargo/bin" \
  "$HOME/.rd/bin" \
  "$HOME/.opencode/bin"

if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
