$configPath = Join-Path $PSScriptRoot 'config.ps1'
if ([System.IO.File]::Exists($configPath)) {
    . $configPath
}
