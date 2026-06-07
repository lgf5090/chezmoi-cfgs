function _fpath_remove -a dir
    set -l idx (contains -i -- "$dir" $PATH)
    while test -n "$idx"
        set -e PATH[$idx]
        set idx (contains -i -- "$dir" $PATH)
    end
end

function _fpath_prepend
    for dir in $argv
        test -d "$dir"; or continue
        _fpath_remove "$dir"
        set -gx PATH "$dir" $PATH
    end
end

function _fpath_append
    for dir in $argv
        test -d "$dir"; or continue
        _fpath_remove "$dir"
        set -gx PATH $PATH "$dir"
    end
end

function _fver_ge -a left right
    set -l v1 (string split . -- "$left")
    set -l v2 (string split . -- "$right")

    for i in 1 2 3
        set -l n1 0
        set -l n2 0
        test (count $v1) -ge $i; and set n1 $v1[$i]
        test (count $v2) -ge $i; and set n2 $v2[$i]

        set n1 (string replace -r '[^0-9].*$' '' -- "$n1")
        set n2 (string replace -r '[^0-9].*$' '' -- "$n2")
        test -n "$n1"; or set n1 0
        test -n "$n2"; or set n2 0

        test $n1 -gt $n2; and return 0
        test $n1 -lt $n2; and return 1
    end

    return 0
end

set -q FISH_PLUGIN_DIR; or set -g FISH_PLUGIN_DIR "$XDG_DATA_HOME/fish/plugins"
set -q FISH_PLUGIN_AUTO_INSTALL; or set -g FISH_PLUGIN_AUTO_INSTALL 1
set -q _FPLUGIN_LOADED; or set -g _FPLUGIN_LOADED

function _fplugin -a owner repo
    if test -z "$owner" -o -z "$repo"
        echo "usage: _fplugin <owner> <repo>" >&2
        return 2
    end

    contains -- "$repo" $_FPLUGIN_LOADED; and return 0

    set -l plugin_dir "$FISH_PLUGIN_DIR/$repo"
    if not test -d "$plugin_dir"
        if test "$FISH_PLUGIN_AUTO_INSTALL" != 1
            echo "fish: plugin missing, skip $repo" >&2
            return 0
        end
        command -q git
        or begin
            echo "fish: git not found, skip $repo" >&2
            return 1
        end
        mkdir -p "$FISH_PLUGIN_DIR"; or return
        git clone --depth=1 "https://github.com/$owner/$repo" "$plugin_dir"
        or begin
            echo "fish: failed to install $repo" >&2
            return 1
        end
    end

    if test -d "$plugin_dir/functions"
        contains -- "$plugin_dir/functions" $fish_function_path
        or set -g fish_function_path "$plugin_dir/functions" $fish_function_path
    end

    if test -d "$plugin_dir/completions"
        contains -- "$plugin_dir/completions" $fish_complete_path
        or set -g fish_complete_path "$plugin_dir/completions" $fish_complete_path
    end

    for file in "$plugin_dir"/conf.d/*.fish "$plugin_dir"/init.fish
        test -r "$file"; and source "$file"
    end

    set -ga _FPLUGIN_LOADED "$repo"
end

function fplugin-update
    command -q git
    or begin
        echo "fish: git not found" >&2
        return 1
    end

    for dir in "$FISH_PLUGIN_DIR"/*
        test -d "$dir/.git"; or continue
        echo "Updating "(basename "$dir")"..."
        git -C "$dir" pull --ff-only
    end
end
