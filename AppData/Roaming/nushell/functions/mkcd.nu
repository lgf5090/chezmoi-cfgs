def --env mkcd [
    dir: string@"nu-complete mkcd-dirs"
] {
    mkdir $dir
    cd $dir
}
