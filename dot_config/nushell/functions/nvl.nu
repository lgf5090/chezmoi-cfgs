def nvl [...args: string] {
    with-env {NVIM_APPNAME: nvim-lite} {
        ^nvim ...$args
    }
}
