if (Test-Command starship) {
    Invoke-Expression (& starship init powershell)
    return
}

$script:PromptHasGit = Test-Command git
$script:PromptHostName = try {
    [Net.Dns]::GetHostName()
} catch {
    [Environment]::MachineName
}

$script:AnsiReset = "`e[0m"
$script:AnsiGray = "`e[90m"
$script:AnsiWhite = "`e[97m"
$script:AnsiRed = "`e[31m"
$script:AnsiGreen = "`e[32m"
$script:AnsiBlue = "`e[34m"
$script:AnsiMagenta = "`e[35m"
$script:AnsiCyan = "`e[36m"

function prompt {
    $success = $?
    $nativeExit = $global:LASTEXITCODE
    $cwd = (Get-Location).ProviderPath
    $homeDir = [Environment]::GetFolderPath('UserProfile')
    if ($homeDir -and $cwd.StartsWith($homeDir, [StringComparison]::OrdinalIgnoreCase)) {
        $cwd = '~' + $cwd.Substring($homeDir.Length)
    }

    $extra = New-Object System.Collections.Generic.List[string]

    if ($env:VIRTUAL_ENV) {
        $extra.Add("$script:AnsiCyan($([IO.Path]::GetFileName($env:VIRTUAL_ENV)))$script:AnsiReset")
    } elseif ($env:CONDA_DEFAULT_ENV -and $env:CONDA_DEFAULT_ENV -ne 'base') {
        $extra.Add("$script:AnsiCyan($env:CONDA_DEFAULT_ENV)$script:AnsiReset")
    }

    if ($script:PromptHasGit) {
        $dir = (Get-Location).ProviderPath
        while ($dir -and $dir -ne [IO.Path]::GetPathRoot($dir)) {
            if (Test-Path -LiteralPath (Join-Path $dir '.git')) {
                $branch = git -C $dir symbolic-ref --short HEAD 2>$null
                if (-not $branch) {
                    $branch = git -C $dir rev-parse --short HEAD 2>$null
                }
                if ($branch) {
                    git -C $dir diff-index --quiet HEAD -- 2>$null
                    $dirty = if ($LASTEXITCODE -eq 0) { '' } else { '*' }
                    $extra.Add("$script:AnsiMagenta$branch$dirty$script:AnsiReset")
                }
                break
            }
            $parent = Split-Path -Parent $dir
            if ($parent -eq $dir) { break }
            $dir = $parent
        }
    }

    $rc = ''
    if (-not $success) {
        $code = if ($nativeExit -and $nativeExit -ne 0) { $nativeExit } else { 1 }
        $rc = " $script:AnsiRed[$code]$script:AnsiReset"
    }

    $time = Get-Date -Format 'HH:mm:ss'
    $user = [Environment]::UserName
    $extraText = if ($extra.Count -gt 0) { ' ' + ($extra -join ' ') } else { '' }

    "$script:AnsiGray[$time]$script:AnsiReset $script:AnsiGreen$user$script:AnsiWhite@$script:PromptHostName$script:AnsiReset $script:AnsiBlue[$cwd]$script:AnsiReset$extraText$rc`n$script:AnsiCyanPS>$script:AnsiReset "
}
