if status is-interactive; and command -q direnv
    direnv hook fish 2>/dev/null | source
end
