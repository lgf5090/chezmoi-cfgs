def --env lf [...args: string] {
    if (which lf | is-empty) {
        print -e "lf: command not found"
        return
    }

    let tmp = ($nu.temp-path | path join $"lf-cwd-(random uuid).txt")
    ^lf $"-last-dir-path=($tmp)" ...$args
    let rc = $env.LAST_EXIT_CODE

    if ($tmp | path exists) {
        let dir = (open --raw $tmp | str trim)
        if ($dir | is-not-empty) and ($dir | path exists) and (($dir | path type) == "dir") and ($dir != $env.PWD) {
            cd $dir
        }
        rm -f $tmp
    }

    if $rc != 0 {
        error make { msg: $"lf exited with code ($rc)" }
    }
}
