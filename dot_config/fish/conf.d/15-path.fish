_fpath_append \
    "$HOME/.local/bin" \
    "$HOME/bin" \
    "$HOME/Applications"

_fpath_prepend \
    "$HOME/.cargo/bin" \
    "$HOME/.rd/bin" \
    "$HOME/.opencode/bin"

if test -x /home/linuxbrew/.linuxbrew/bin/brew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv fish | source
else if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
else if test -x /usr/local/bin/brew
    /usr/local/bin/brew shellenv fish | source
end
