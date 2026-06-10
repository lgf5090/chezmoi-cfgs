$homeDir = [Environment]::GetFolderPath('UserProfile')

$fnmActivate = if ([string]::IsNullOrWhiteSpace($env:POWERSHELL_FNM_ACTIVATE)) {
    'default'
} else {
    $env:POWERSHELL_FNM_ACTIVATE.ToLowerInvariant()
}

switch ($fnmActivate) {
    { $_ -in @('full', 'use-on-cd', '1', 'yes', 'true', 'env') } {
        $fnmCandidates = @()
        if (-not [string]::IsNullOrWhiteSpace($env:FNM_DIR)) {
            $fnmCandidates += @(
                (Join-Path $env:FNM_DIR 'fnm'),
                (Join-Path $env:FNM_DIR 'fnm.exe')
            )
        }
        $fnmCandidates += @(
            (Join-Path $homeDir '.local/bin/fnm'),
            '/home/linuxbrew/.linuxbrew/bin/fnm',
            (Join-Path $homeDir '.linuxbrew/bin/fnm'),
            '/opt/homebrew/bin/fnm',
            '/usr/local/bin/fnm'
        )

        foreach ($candidate in $fnmCandidates) {
            if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
            $script:PowerShellFnmExe = (Resolve-Path -LiteralPath $candidate).ProviderPath
            break
        }

        if ([string]::IsNullOrWhiteSpace($script:PowerShellFnmExe) -and $env:POWERSHELL_FNM_DISCOVERY -eq '1') {
            $script:PowerShellFnmExe = (Get-Command fnm -CommandType Application -ErrorAction SilentlyContinue).Source
        }

        if (-not [string]::IsNullOrWhiteSpace($script:PowerShellFnmExe)) {
            $fnmArgs = if ($fnmActivate -eq 'env') {
                @('env', '--shell', 'powershell')
            } else {
                @('env', '--use-on-cd', '--shell', 'powershell')
            }

            $hook = & $script:PowerShellFnmExe @fnmArgs 2>$null
            if ([string]::IsNullOrWhiteSpace(($hook | Out-String)) -and $fnmActivate -ne 'env') {
                $hook = & $script:PowerShellFnmExe env --use-on-cd 2>$null
            }
            if (-not [string]::IsNullOrWhiteSpace(($hook | Out-String))) {
                Invoke-Expression ($hook | Out-String)
            }
        }
        break
    }
    { $_ -in @('none', '0', 'no', 'false') } {
        break
    }
    default {
        break
    }
}
