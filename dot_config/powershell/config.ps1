# Fish-style PowerShell entrypoint.

if ([string]::IsNullOrWhiteSpace($env:POWERSHELL_CONFIG_DIR)) {
    $env:POWERSHELL_CONFIG_DIR = $PSScriptRoot
}

$global:PowerShellConfigDir = (Resolve-Path -LiteralPath $env:POWERSHELL_CONFIG_DIR).ProviderPath

function Get-PSConfigFiles {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return
    }

    Get-ChildItem -LiteralPath $Path -Filter '*.ps1' -File |
        Sort-Object -Property Name
}

foreach ($file in Get-PSConfigFiles (Join-Path $global:PowerShellConfigDir 'functions')) {
    . $file.FullName
}

foreach ($file in Get-PSConfigFiles (Join-Path $global:PowerShellConfigDir 'conf.d')) {
    . $file.FullName
}

foreach ($file in Get-PSConfigFiles (Join-Path $global:PowerShellConfigDir 'completions')) {
    . $file.FullName
}

Remove-Item Function:\Get-PSConfigFiles -ErrorAction SilentlyContinue
