$homeDir = [Environment]::GetFolderPath('UserProfile')

Add-PathAppend `
    (Join-Path $homeDir '.local/bin') `
    (Join-Path $homeDir 'bin') `
    (Join-Path $homeDir 'Applications')

Add-PathPrepend `
    (Join-Path $homeDir '.cargo/bin') `
    (Join-Path $homeDir '.rd/bin') `
    (Join-Path $homeDir '.opencode/bin')

if ($script:IsWindowsPlatform) {
    Add-PathPrepend `
        (Join-Path $homeDir 'scoop/shims') `
        (Join-Path $env:LOCALAPPDATA 'Microsoft/WindowsApps') `
        (Join-Path $env:APPDATA 'npm')
} else {
    Add-PathPrepend `
        '/home/linuxbrew/.linuxbrew/bin' `
        '/home/linuxbrew/.linuxbrew/sbin' `
        '/opt/homebrew/bin' `
        '/opt/homebrew/sbin' `
        '/usr/local/bin'
}
