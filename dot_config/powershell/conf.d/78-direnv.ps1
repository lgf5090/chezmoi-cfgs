if (Test-Command direnv) {
    $hook = & direnv hook pwsh 2>$null
    if ([string]::IsNullOrWhiteSpace(($hook | Out-String))) {
        $hook = & direnv hook powershell 2>$null
    }
    if (-not [string]::IsNullOrWhiteSpace(($hook | Out-String))) {
        Invoke-Expression ($hook | Out-String)
    }
}
