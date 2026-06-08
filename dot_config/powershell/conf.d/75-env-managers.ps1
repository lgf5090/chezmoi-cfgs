foreach ($manager in @(
    @{ Name = 'rbenv'; Root = $env:RBENV_ROOT },
    @{ Name = 'nodenv'; Root = $env:NODENV_ROOT },
    @{ Name = 'goenv'; Root = $env:GOENV_ROOT },
    @{ Name = 'jenv'; Root = $env:JENV_ROOT }
)) {
    $managerName = $manager.Name
    if ([string]::IsNullOrWhiteSpace($manager.Root)) {
        continue
    }

    Add-PathPrepend `
        (Join-Path $manager.Root 'bin') `
        (Join-Path $manager.Root 'shims')

    if (-not (Test-Command $managerName)) { continue }

    $hook = & $managerName init - powershell 2>$null
    if (-not [string]::IsNullOrWhiteSpace(($hook | Out-String))) {
        Invoke-Expression ($hook | Out-String)
    }
}
