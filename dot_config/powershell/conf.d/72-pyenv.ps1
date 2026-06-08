$homeDir = [Environment]::GetFolderPath('UserProfile')

if ([string]::IsNullOrWhiteSpace($env:PYENV_ROOT)) {
    foreach ($candidate in @(
        (Join-Path $homeDir '.pyenv/pyenv-win'),
        (Join-Path $homeDir '.pyenv')
    )) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
        $env:PYENV_ROOT = (Resolve-Path -LiteralPath $candidate).ProviderPath
        break
    }
}

if (-not [string]::IsNullOrWhiteSpace($env:PYENV_ROOT)) {
    Add-PathPrepend `
        (Join-Path $env:PYENV_ROOT 'bin') `
        (Join-Path $env:PYENV_ROOT 'shims') `
        (Join-Path $env:PYENV_ROOT 'pyenv-win/bin') `
        (Join-Path $env:PYENV_ROOT 'pyenv-win/shims')
}
