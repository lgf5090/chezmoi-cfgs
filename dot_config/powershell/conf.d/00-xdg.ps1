if ([string]::IsNullOrWhiteSpace($HOME)) {
    $HOME = [Environment]::GetFolderPath('UserProfile')
}

if ([string]::IsNullOrWhiteSpace($env:XDG_CONFIG_HOME)) {
    $env:XDG_CONFIG_HOME = Join-Path $HOME '.config'
}
if ([string]::IsNullOrWhiteSpace($env:XDG_DATA_HOME)) {
    $env:XDG_DATA_HOME = Join-Path $HOME '.local/share'
}
if ([string]::IsNullOrWhiteSpace($env:XDG_STATE_HOME)) {
    $env:XDG_STATE_HOME = Join-Path $HOME '.local/state'
}
if ([string]::IsNullOrWhiteSpace($env:XDG_CACHE_HOME)) {
    $env:XDG_CACHE_HOME = Join-Path $HOME '.cache'
}

foreach ($dir in @(
    (Join-Path $env:XDG_STATE_HOME 'powershell'),
    (Join-Path $env:XDG_CACHE_HOME 'powershell')
)) {
    if (-not [System.IO.Directory]::Exists($dir)) {
        [System.IO.Directory]::CreateDirectory($dir) | Out-Null
    }
}
