for manager in rbenv nodenv goenv
    if command -q "$manager"
        "$manager" init - fish 2>/dev/null | source
    end
end

if command -q jenv
    jenv init - fish 2>/dev/null | source
end
