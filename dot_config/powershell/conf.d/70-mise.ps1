$homeDir = [Environment]::GetFolderPath('UserProfile')
if ([string]::IsNullOrWhiteSpace($env:MISE_DATA_DIR)) {
    $env:MISE_DATA_DIR = Join-Path $env:XDG_DATA_HOME 'mise'
}

$mise = Get-Command -Name mise -ErrorAction SilentlyContinue
if (-not $mise) {
    foreach ($candidate in @(
        (Join-Path $homeDir '.local/bin/mise'),
        '/home/linuxbrew/.linuxbrew/bin/mise',
        (Join-Path $homeDir '.linuxbrew/bin/mise'),
        '/opt/homebrew/bin/mise',
        '/usr/local/bin/mise',
        '/opt/mise/bin/mise'
    )) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        $mise = Get-Item -LiteralPath $candidate
        break
    }
}

if ($mise) {
    $misePath = if ($mise.Source) { $mise.Source } else { $mise.FullName }
    $script:PowerShellMiseExe = $misePath
    function global:mise {
        & $script:PowerShellMiseExe @args
    }
}

Add-PathPrepend `
    (Join-Path $homeDir '.mise/shims') `
    (Join-Path $env:MISE_DATA_DIR 'shims')
