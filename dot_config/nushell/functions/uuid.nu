def "nu-complete uuid-count" []: nothing -> list<int> {
    [1 2 3 5 10 20 50 100]
}

def _uuid-help []: nothing -> nothing {
    [
        'usage:'
        '  uuid'
        '  uuid -n COUNT'
        '  uuid -h | --help'
        ''
        'Generate RFC 4122 version 4 UUIDs using Nushell builtins.'
    ] | str join (char nl) | print
}

def uuid [
    --count (-n): int@"nu-complete uuid-count" = 1 # Number of UUIDs to generate
    --help (-h)                                    # Show help
]: nothing -> any {
    if $help {
        _uuid-help
        return
    }

    if $count < 1 {
        error make {msg: 'uuid: --count requires a positive integer'}
    }

    if $count == 1 {
        random uuid
    } else {
        1..$count | each {|| random uuid }
    }
}
