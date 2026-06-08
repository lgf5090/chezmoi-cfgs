set -q FNM_DIR; and _fpath_prepend "$FNM_DIR"

if command -q fnm
    fnm env --use-on-cd --shell fish 2>/dev/null | source
end
