if ($global:PowerShellLocalLoaderVersion -ne 1) {
    . (Join-Path $PSScriptRoot '01-helpers.ps1')
}

$localAliasesFile = if ([string]::IsNullOrWhiteSpace($env:POWERSHELL_LOCAL_ALIASES_FILE)) {
    Join-Path $HOME '.aliases'
} else {
    $env:POWERSHELL_LOCAL_ALIASES_FILE
}

Import-LocalAliasFile -Path $localAliasesFile
