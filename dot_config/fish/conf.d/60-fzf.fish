if command -q fd
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --strip-cwd-prefix'
else
    set -gx FZF_DEFAULT_COMMAND 'find . -type f'
end

set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_DEFAULT_OPTS '--height=60% --layout=reverse --border=rounded --preview-window=right:65%:wrap:border-left'

if command -q bat
    set -gx _FZF_PREVIEW_CMD 'bat --color=always --style=plain,numbers --line-range=:500 {}'
else
    set -gx _FZF_PREVIEW_CMD 'sed -n "1,200p" {} 2>/dev/null'
end
set -gx FZF_CTRL_T_OPTS "--preview '$_FZF_PREVIEW_CMD'"

if status is-interactive; and command -q fzf
    set -l fzf_ver (fzf --version 2>/dev/null | awk '{print $1}')

    if _fver_ge "$fzf_ver" 0.48.0
        fzf --fish | source
    else
        set -l fzf_dirs /usr/share/fzf /usr/share/doc/fzf/examples
        if command -q brew
            set -l fzf_brew (brew --prefix fzf 2>/dev/null)
            test -n "$fzf_brew"; and set fzf_dirs "$fzf_brew/shell" $fzf_dirs
        end

        for dir in $fzf_dirs
            test -d "$dir"; or continue
            test -r "$dir/key-bindings.fish"; and source "$dir/key-bindings.fish"
            test -r "$dir/completion.fish"; and source "$dir/completion.fish"
            break
        end
    end
end
