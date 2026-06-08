if (-not [string]::IsNullOrWhiteSpace($env:FNM_DIR)) {
    Add-PathPrepend $env:FNM_DIR
}

if (Test-Command fnm) {
    $hook = & fnm env --use-on-cd --shell powershell 2>$null
    if ([string]::IsNullOrWhiteSpace(($hook | Out-String))) {
        $hook = & fnm env --use-on-cd 2>$null
    }
    if (-not [string]::IsNullOrWhiteSpace(($hook | Out-String))) {
        Invoke-Expression ($hook | Out-String)
    }
}
