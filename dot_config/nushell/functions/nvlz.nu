def nvlz [...args: string] {
    with-env {NVIM_APPNAME: nvim-lazy} {
        ^nvim ...$args
    }
}
