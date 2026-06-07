$homeDir = [Environment]::GetFolderPath('UserProfile')

if ([string]::IsNullOrWhiteSpace($env:NPM_CONFIG_PREFIX)) {
    $env:NPM_CONFIG_PREFIX = Join-Path $homeDir '.npm-global'
}
if ([string]::IsNullOrWhiteSpace($env:PNPM_HOME)) {
    $env:PNPM_HOME = Join-Path $homeDir '.pnpm-global'
}

Add-PathPrepend `
    (Join-Path $env:NPM_CONFIG_PREFIX 'bin') `
    $env:NPM_CONFIG_PREFIX `
    $env:PNPM_HOME `
    (Join-Path $homeDir '.bun/bin') `
    (Join-Path $homeDir '.deno/bin')

if ($script:IsWindowsPlatform -and $env:APPDATA) {
    Add-PathPrepend (Join-Path $env:APPDATA 'npm')
}
