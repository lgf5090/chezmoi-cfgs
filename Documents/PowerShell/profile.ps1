# Load the PowerShell configuration for the current user when available.
if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    $configPath = [System.IO.Path]::Combine($env:USERPROFILE, '.config', 'powershell', 'config.ps1')
    if ([System.IO.File]::Exists($configPath)) {
        . $configPath
    }
}
