function Show-RandstrHelp {
    @'
usage:
  randstr [LENGTH] [COUNT]
  randstr -l LENGTH -n COUNT [options]
  randstr -h | --help

Generate random strings using PowerShell built-in language features.

options:
  -l, --length N        characters per string, default: 16
  -n, --count N         number of strings, default: 1
  --lower               use a-z
  --upper               use A-Z
  --alpha               use A-Za-z
  --digits              use 0-9
  --alnum               use A-Za-z0-9, default
  --hex                 use 0-9a-f
  --safe                use A-Za-z0-9_-
  --symbols             use shell-friendly symbols
  --alphabet CHARS      use a custom character set
  --prefix TEXT         prepend TEXT to each string
  --suffix TEXT         append TEXT to each string
'@
}

function ConvertTo-RandstrPositiveInt {
    param(
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$Label
    )

    $number = 0
    if (-not [int]::TryParse($Value, [ref]$number) -or $number -lt 1) {
        throw "randstr: $Label requires a positive integer"
    }
    $number
}

function New-RandstrString {
    param(
        [Parameter(Mandatory)][int]$Length,
        [Parameter(Mandatory)][string]$Alphabet,
        [string]$Prefix = '',
        [string]$Suffix = ''
    )

    $builder = [System.Text.StringBuilder]::new($Length)
    for ($i = 0; $i -lt $Length; $i++) {
        $index = [System.Security.Cryptography.RandomNumberGenerator]::GetInt32($Alphabet.Length)
        [void]$builder.Append($Alphabet[$index])
    }

    "$Prefix$($builder.ToString())$Suffix"
}

function randstr {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $length = 16
    $count = 1
    $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    $prefix = ''
    $suffix = ''
    $positionals = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        $arg = $Arguments[$i]
        switch ($arg) {
            { $_ -in @('-h', '--help') } {
                Show-RandstrHelp
                return
            }
            { $_ -in @('-l', '--length') } {
                if (++$i -ge $Arguments.Count) { throw "randstr: $arg requires a positive integer" }
                $length = ConvertTo-RandstrPositiveInt -Value $Arguments[$i] -Label $arg
                continue
            }
            { $_ -in @('-n', '--count') } {
                if (++$i -ge $Arguments.Count) { throw "randstr: $arg requires a positive integer" }
                $count = ConvertTo-RandstrPositiveInt -Value $Arguments[$i] -Label $arg
                continue
            }
            '--lower' { $alphabet = 'abcdefghijklmnopqrstuvwxyz'; continue }
            '--upper' { $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'; continue }
            '--alpha' { $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'; continue }
            '--digits' { $alphabet = '0123456789'; continue }
            '--alnum' { $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'; continue }
            '--hex' { $alphabet = '0123456789abcdef'; continue }
            '--safe' { $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-'; continue }
            '--symbols' { $alphabet = '!#$%&()*+,-./:;<=>?@[]^_{|}~'; continue }
            '--alphabet' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrEmpty($Arguments[$i])) {
                    throw 'randstr: --alphabet requires CHARS'
                }
                $alphabet = $Arguments[$i]
                continue
            }
            '--prefix' {
                if (++$i -ge $Arguments.Count) { throw 'randstr: --prefix requires TEXT' }
                $prefix = $Arguments[$i]
                continue
            }
            '--suffix' {
                if (++$i -ge $Arguments.Count) { throw 'randstr: --suffix requires TEXT' }
                $suffix = $Arguments[$i]
                continue
            }
            '--' {
                for ($j = $i + 1; $j -lt $Arguments.Count; $j++) {
                    if ($positionals.Count -eq 0) {
                        $length = ConvertTo-RandstrPositiveInt -Value $Arguments[$j] -Label 'LENGTH'
                    } elseif ($positionals.Count -eq 1) {
                        $count = ConvertTo-RandstrPositiveInt -Value $Arguments[$j] -Label 'COUNT'
                    } else {
                        throw "randstr: unexpected argument: $($Arguments[$j])"
                    }
                    $positionals.Add($Arguments[$j])
                }
                $i = $Arguments.Count
                continue
            }
            default {
                if ($arg.StartsWith('-')) { throw "randstr: unknown option: $arg" }
                if ($positionals.Count -eq 0) {
                    $length = ConvertTo-RandstrPositiveInt -Value $arg -Label 'LENGTH'
                } elseif ($positionals.Count -eq 1) {
                    $count = ConvertTo-RandstrPositiveInt -Value $arg -Label 'COUNT'
                } else {
                    throw "randstr: unexpected argument: $arg"
                }
                $positionals.Add($arg)
            }
        }
    }

    if ([string]::IsNullOrEmpty($alphabet)) {
        throw 'randstr: alphabet must not be empty'
    }

    for ($i = 0; $i -lt $count; $i++) {
        New-RandstrString -Length $length -Alphabet $alphabet -Prefix $prefix -Suffix $suffix
    }
}

Register-ArgumentCompleter -CommandName randstr -ParameterName Arguments -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $elements = @($commandAst.CommandElements | ForEach-Object { $_.ToString() })
    $tokens = if ($elements.Count -gt 1) { @($elements[1..($elements.Count - 1)]) } else { @() }
    $isCompletingCurrent = ($tokens.Count -gt 0) -and ($tokens[-1] -eq $wordToComplete)
    $completed = if ($isCompletingCurrent) {
        if ($tokens.Count -gt 1) { @($tokens[0..($tokens.Count - 2)]) } else { @() }
    } else {
        $tokens
    }
    $prev = if ($completed.Count -gt 0) { $completed[-1] } else { '' }

    $candidates = switch ($prev) {
        { $_ -in @('-l', '--length') } { @('8', '12', '16', '24', '32', '48', '64'); break }
        { $_ -in @('-n', '--count') } { @('1', '2', '3', '5', '10', '20', '50', '100'); break }
        { $_ -in @('--alphabet', '--prefix', '--suffix') } { @(); break }
        default {
            @(
                '-h', '--help', '-l', '--length', '-n', '--count',
                '--lower', '--upper', '--alpha', '--digits', '--alnum',
                '--hex', '--safe', '--symbols', '--alphabet', '--prefix', '--suffix'
            )
        }
    }

    $candidates |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
