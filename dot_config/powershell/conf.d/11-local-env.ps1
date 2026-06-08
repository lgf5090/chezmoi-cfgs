if ($global:PowerShellLocalLoaderVersion -ne 1) {
    . (Join-Path $PSScriptRoot '01-helpers.ps1')
}

$localEnvFile = if ([string]::IsNullOrWhiteSpace($env:POWERSHELL_LOCAL_ENVS_FILE)) {
    Join-Path $HOME '.envs'
} else {
    $env:POWERSHELL_LOCAL_ENVS_FILE
}

Import-LocalEnvFile -Path $localEnvFile
