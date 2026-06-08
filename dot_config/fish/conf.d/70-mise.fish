set -q MISE_DATA_DIR; or set -gx MISE_DATA_DIR "$XDG_DATA_HOME/mise"

set -l mise (command -s mise 2>/dev/null)
if test -z "$mise"
    for candidate in \
        "$HOME/.local/bin/mise" \
        /home/linuxbrew/.linuxbrew/bin/mise \
        "$HOME/.linuxbrew/bin/mise" \
        /opt/homebrew/bin/mise \
        /usr/local/bin/mise \
        /opt/mise/bin/mise
        test -x "$candidate"; or continue
        set mise "$candidate"
        break
    end
end

if test -n "$mise"; and test -x "$mise"
    "$mise" activate fish | source
end

_fpath_prepend "$HOME/.mise/shims" "$MISE_DATA_DIR/shims"
