def "nu-complete mkcd-dirs" [] {
    ls -a
    | where type == dir
    | get name
}
