$homeDir = [Environment]::GetFolderPath('UserProfile')

if ([string]::IsNullOrWhiteSpace($env:NVM_DIR)) {
    $env:NVM_DIR = Join-Path $homeDir '.nvm'
}

if ($script:IsWindowsPlatform) {
    if ([string]::IsNullOrWhiteSpace($env:NVM_HOME)) {
        foreach ($candidate in @(
            $(if ($env:APPDATA) { Join-Path $env:APPDATA 'nvm' }),
            (Join-Path $homeDir 'scoop/apps/nvm/current'),
            (Join-Path $homeDir '.nvm')
        )) {
            if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
            if (-not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
            $env:NVM_HOME = (Resolve-Path -LiteralPath $candidate).ProviderPath
            break
        }
    }

    if ([string]::IsNullOrWhiteSpace($env:NVM_SYMLINK)) {
        foreach ($candidate in @(
            $(if ($env:ProgramFiles) { Join-Path $env:ProgramFiles 'nodejs' }),
            (Join-Path $homeDir 'scoop/apps/nodejs/current')
        )) {
            if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
            if (-not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
            $env:NVM_SYMLINK = (Resolve-Path -LiteralPath $candidate).ProviderPath
            break
        }
    }
}

Add-PathPrepend $env:NVM_HOME $env:NVM_SYMLINK
