if status is-interactive
    fish_vi_key_bindings

    bind -M insert \ca beginning-of-line
    bind -M insert \ce end-of-line
    bind -M insert \cf forward-char
    bind -M insert \cb backward-char
    bind -M insert \ck kill-line
    bind -M insert \cu backward-kill-line
    bind -M insert \cw backward-kill-word

    bind -M default \ca beginning-of-line
    bind -M default \ce end-of-line
    bind -M default \cf forward-char
    bind -M default \cb backward-char
    bind -M default \ck kill-line
    bind -M default \cu backward-kill-line
    bind -M default \cw backward-kill-word
end
