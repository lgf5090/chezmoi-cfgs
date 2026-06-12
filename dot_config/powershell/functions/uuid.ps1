function Show-UuidHelp {
    @'
usage:
  uuid
  uuid -n COUNT
  uuid -h | --help

Generate RFC 4122 version 4 UUIDs using PowerShell built-in language features.
'@
}

function uuid {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $count = 1
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        $arg = $Arguments[$i]
        switch ($arg) {
            { $_ -in @('-h', '--help') } {
                Show-UuidHelp
                return
            }
            { $_ -in @('-n', '--count') } {
                if (++$i -ge $Arguments.Count -or -not [int]::TryParse($Arguments[$i], [ref]$count) -or $count -lt 1) {
                    throw "uuid: $arg requires a positive integer"
                }
                continue
            }
            '--' {
                if ($i + 1 -lt $Arguments.Count) {
                    throw "uuid: unexpected argument: $($Arguments[$i + 1])"
                }
                continue
            }
            default {
                if ($arg.StartsWith('-')) {
                    throw "uuid: unknown option: $arg"
                }
                throw "uuid: unexpected argument: $arg"
            }
        }
    }

    for ($i = 0; $i -lt $count; $i++) {
        [guid]::NewGuid().ToString()
    }
}

Register-ArgumentCompleter -CommandName uuid -ParameterName Arguments -ScriptBlock {
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

    $candidates = if ($prev -in @('-n', '--count')) {
        @('1', '2', '3', '5', '10', '20', '50', '100')
    } else {
        @('-h', '--help', '-n', '--count')
    }

    $candidates |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
