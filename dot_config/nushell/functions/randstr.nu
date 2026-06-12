def "nu-complete randstr-length" []: nothing -> list<int> {
    [8 12 16 24 32 48 64]
}

def "nu-complete randstr-count" []: nothing -> list<int> {
    [1 2 3 5 10 20 50 100]
}

def _randstr-help []: nothing -> nothing {
    [
        'usage:'
        '  randstr [LENGTH] [COUNT]'
        '  randstr -l LENGTH -n COUNT [options]'
        '  randstr -h | --help'
        ''
        'Generate random strings using Nushell builtins.'
        ''
        'options:'
        '  -l, --length N        characters per string, default: 16'
        '  -n, --count N         number of strings, default: 1'
        '  --lower               use a-z'
        '  --upper               use A-Z'
        '  --alpha               use A-Za-z'
        '  --digits              use 0-9'
        '  --alnum               use A-Za-z0-9, default'
        '  --hex                 use 0-9a-f'
        '  --safe                use A-Za-z0-9_-'
        '  --symbols             use shell-friendly symbols'
        '  --alphabet CHARS      use a custom character set'
        '  --prefix TEXT         prepend TEXT to each string'
        '  --suffix TEXT         append TEXT to each string'
    ] | str join (char nl) | print
}

def _randstr-positive-int [value: int, label: string]: nothing -> int {
    if $value < 1 {
        error make {msg: $'randstr: ($label) requires a positive integer'}
    }

    $value
}

def _randstr-alphabet [
    --lower
    --upper
    --alpha
    --digits
    --alnum
    --hex
    --safe
    --symbols
    --alphabet: string
]: nothing -> string {
    let selections = [
        {enabled: $lower, value: 'abcdefghijklmnopqrstuvwxyz'}
        {enabled: $upper, value: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'}
        {enabled: $alpha, value: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'}
        {enabled: $digits, value: '0123456789'}
        {enabled: $alnum, value: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'}
        {enabled: $hex, value: '0123456789abcdef'}
        {enabled: $safe, value: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-'}
        {enabled: $symbols, value: '!#$%&()*+,-./:;<=>?@[]^_{|}~'}
    ] | where enabled == true

    if $alphabet != null {
        if ($alphabet | is-empty) {
            error make {msg: 'randstr: --alphabet requires CHARS'}
        }
        if (($selections | length) > 0) {
            error make {msg: 'randstr: use either --alphabet or one built-in character set option'}
        }
        return $alphabet
    }

    if (($selections | length) > 1) {
        error make {msg: 'randstr: choose one character set option, or use --alphabet to combine sets'}
    }

    if (($selections | length) == 1) {
        $selections | first | get value
    } else {
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    }
}

def _randstr-one [
    length: int
    alphabet: string
    prefix: string
    suffix: string
]: nothing -> string {
    let chars = ($alphabet | split chars)
    let max_index = (($chars | length) - 1)
    let body = (
        1..$length
        | each {|| $chars | get (random int 0..$max_index) }
        | str join
    )

    $'($prefix)($body)($suffix)'
}

def randstr [
    pos_length?: int@"nu-complete randstr-length" # Characters per string
    pos_count?: int@"nu-complete randstr-count"   # Number of strings
    --length (-l): int@"nu-complete randstr-length"
    --count (-n): int@"nu-complete randstr-count"
    --lower                                      # Use a-z
    --upper                                      # Use A-Z
    --alpha                                      # Use A-Za-z
    --digits                                     # Use 0-9
    --alnum                                      # Use A-Za-z0-9
    --hex                                        # Use 0-9a-f
    --safe                                       # Use A-Za-z0-9_-
    --symbols                                    # Use shell-friendly symbols
    --alphabet: string                           # Custom character set
    --prefix: string = ''                        # Prefix each string
    --suffix: string = ''                        # Suffix each string
    --help (-h)                                  # Show help
]: nothing -> any {
    if $help {
        _randstr-help
        return
    }

    let actual_length = (
        if $length != null {
            _randstr-positive-int $length '--length'
        } else if $pos_length != null {
            _randstr-positive-int $pos_length 'LENGTH'
        } else {
            16
        }
    )
    let actual_count = (
        if $count != null {
            _randstr-positive-int $count '--count'
        } else if $pos_count != null {
            _randstr-positive-int $pos_count 'COUNT'
        } else {
            1
        }
    )
    let actual_alphabet = (
        _randstr-alphabet
            --lower=$lower
            --upper=$upper
            --alpha=$alpha
            --digits=$digits
            --alnum=$alnum
            --hex=$hex
            --safe=$safe
            --symbols=$symbols
            --alphabet=$alphabet
    )

    if $actual_count == 1 {
        _randstr-one $actual_length $actual_alphabet $prefix $suffix
    } else {
        1..$actual_count | each {|| _randstr-one $actual_length $actual_alphabet $prefix $suffix }
    }
}
