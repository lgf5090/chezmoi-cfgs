# Fish-style PowerShell entrypoint.

if ([string]::IsNullOrWhiteSpace($env:POWERSHELL_CONFIG_DIR)) {
    $env:POWERSHELL_CONFIG_DIR = $PSScriptRoot
}

$global:PowerShellConfigDir = [System.IO.Path]::GetFullPath($env:POWERSHELL_CONFIG_DIR)

foreach ($configSubdir in @('functions', 'conf.d', 'completions')) {
    $configPath = Join-Path $global:PowerShellConfigDir $configSubdir

    if (-not [System.IO.Directory]::Exists($configPath)) {
        continue
    }

    $configFiles = [System.IO.Directory]::GetFiles($configPath, '*.ps1')
    [System.Array]::Sort($configFiles, [System.StringComparer]::OrdinalIgnoreCase)
    foreach ($file in $configFiles) {
        . $file
    }
}
