$homeDir = [Environment]::GetFolderPath('UserProfile')

$direnvCandidates = @(
    (Join-Path $homeDir '.local/bin/direnv'),
    '/home/linuxbrew/.linuxbrew/bin/direnv',
    (Join-Path $homeDir '.linuxbrew/bin/direnv'),
    '/opt/homebrew/bin/direnv',
    '/usr/local/bin/direnv'
)

foreach ($candidate in $direnvCandidates) {
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
    $script:PowerShellDirenvExe = (Resolve-Path -LiteralPath $candidate).ProviderPath
    break
}

if ([string]::IsNullOrWhiteSpace($script:PowerShellDirenvExe) -and $env:POWERSHELL_DIRENV_DISCOVERY -eq '1') {
    $script:PowerShellDirenvExe = (Get-Command direnv -CommandType Application -ErrorAction SilentlyContinue).Source
}

if (-not [string]::IsNullOrWhiteSpace($script:PowerShellDirenvExe)) {
    $hook = & $script:PowerShellDirenvExe hook pwsh 2>$null
    if ([string]::IsNullOrWhiteSpace(($hook | Out-String))) {
        $hook = & $script:PowerShellDirenvExe hook powershell 2>$null
    }
    if (-not [string]::IsNullOrWhiteSpace(($hook | Out-String))) {
        Invoke-Expression ($hook | Out-String)
    }
}
