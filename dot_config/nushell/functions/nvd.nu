def nvd [...args: string] {
    with-env {NVIM_APPNAME: nvim-dev} {
        ^nvim ...$args
    }
}
