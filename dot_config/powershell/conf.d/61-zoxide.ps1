$homeDir = [Environment]::GetFolderPath('UserProfile')
$zoxideCandidates = @(
    (Join-Path $homeDir '.local/bin/zoxide'),
    (Join-Path $(if ($env:CARGO_HOME) { $env:CARGO_HOME } else { Join-Path $homeDir '.cargo' }) 'bin/zoxide'),
    '/home/linuxbrew/.linuxbrew/bin/zoxide',
    (Join-Path $homeDir '.linuxbrew/bin/zoxide'),
    '/opt/homebrew/bin/zoxide',
    '/usr/local/bin/zoxide',
    '/usr/bin/zoxide'
)

if ($global:ShellsOS -eq 'windows') {
    $zoxideCandidates += @(
        (Join-Path $homeDir 'scoop/shims/zoxide.exe'),
        $(if ($env:PROGRAMDATA) { Join-Path $env:PROGRAMDATA 'scoop/shims/zoxide.exe' }),
        $(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Links/zoxide.exe' })
    )
}

foreach ($candidate in $zoxideCandidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
    if (-not [System.IO.File]::Exists($candidate)) { continue }
    $global:PowerShellZoxideExe = [System.IO.Path]::GetFullPath($candidate)
    break
}

if ([string]::IsNullOrWhiteSpace($global:PowerShellZoxideExe) -and $env:POWERSHELL_ZOXIDE_DISCOVERY -eq '1') {
    $global:PowerShellZoxideExe = (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue).Source
}

if (-not [string]::IsNullOrWhiteSpace($global:PowerShellZoxideExe)) {
    function global:z {
        param([Parameter(ValueFromRemainingArguments)][string[]]$Query)

        if ($Query.Count -eq 0) {
            Set-Location -LiteralPath $HOME
            return
        }

        if ($Query.Count -eq 1 -and (Test-Path -LiteralPath $Query[0] -PathType Container)) {
            Set-Location -LiteralPath $Query[0]
            return
        }

        $dir = & $global:PowerShellZoxideExe query -- @Query 2>$null
        if (-not [string]::IsNullOrWhiteSpace($dir)) {
            Set-Location -LiteralPath $dir
        }
    }

    function global:zi {
        param([Parameter(ValueFromRemainingArguments)][string[]]$Query)

        $dir = & $global:PowerShellZoxideExe query -i -- @Query 2>$null
        if (-not [string]::IsNullOrWhiteSpace($dir)) {
            Set-Location -LiteralPath $dir
        }
    }

    $location = Get-Location
    $global:PowerShellZoxideOldPwd = if ($location.Provider.Name -eq 'FileSystem') {
        $location.ProviderPath
    } else {
        $null
    }
    $global:PowerShellZoxideHookEnabled = $true

    function global:__PowerShellZoxideHook {
        if ([string]::IsNullOrWhiteSpace($global:PowerShellZoxideExe)) { return }

        $location = Get-Location
        if ($location.Provider.Name -ne 'FileSystem') { return }

        $pwd = $location.ProviderPath
        if ($pwd -eq $global:PowerShellZoxideOldPwd) { return }

        & $global:PowerShellZoxideExe add -- $pwd *> $null
        $global:PowerShellZoxideOldPwd = $pwd
    }
}
