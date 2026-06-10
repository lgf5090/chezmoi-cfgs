$homeDir = [Environment]::GetFolderPath('UserProfile')

$miseCandidates = @(
    $env:MISE_EXE,
    (Join-Path $homeDir '.local/bin/mise'),
    '/home/linuxbrew/.linuxbrew/bin/mise',
    (Join-Path $homeDir '.linuxbrew/bin/mise'),
    '/opt/homebrew/bin/mise',
    '/usr/local/bin/mise',
    '/opt/mise/bin/mise'
)

if ($global:ShellsOS -eq 'windows') {
    $miseCandidates += @(
        (Join-Path $homeDir 'scoop/shims/mise.exe'),
        $(if ($env:PROGRAMDATA) { Join-Path $env:PROGRAMDATA 'scoop/shims/mise.exe' }),
        $(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Links/mise.exe' })
    )
}

foreach ($candidate in $miseCandidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
    if (-not [System.IO.File]::Exists($candidate)) { continue }
    $script:PowerShellMiseExe = [System.IO.Path]::GetFullPath($candidate)
    break
}

if ([string]::IsNullOrWhiteSpace($script:PowerShellMiseExe) -and $env:POWERSHELL_MISE_DISCOVERY -eq '1') {
    $script:PowerShellMiseExe = (Get-Command mise -CommandType Application -ErrorAction SilentlyContinue).Source
}

if (-not [string]::IsNullOrWhiteSpace($script:PowerShellMiseExe)) {
    function global:mise {
        & $script:PowerShellMiseExe @args
    }
}
