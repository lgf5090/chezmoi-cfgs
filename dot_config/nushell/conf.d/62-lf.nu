if ($env.XDG_CONFIG_HOME | path join "lf" "icons" | path exists) {
    $env.LF_ICONS = (open --raw ($env.XDG_CONFIG_HOME | path join "lf" "icons") | lines | str join ":")
}

if (which lf | is-not-empty) {
    def --env lf [...args: string] {
        let tmp = (mktemp -t lf-cwd.XXXXXX)

        try {
            ^lf $"-last-dir-path=($tmp)" ...$args
        } catch {
            rm -f $tmp
            return
        }

        if ($tmp | path exists) {
            let dir = (open --raw $tmp | str trim)
            if ($dir | is-not-empty) and ($dir | path exists) and (($dir | path type) == "dir") and ($dir != $env.PWD) {
                cd $dir
            }
        }

        rm -f $tmp
    }
}
