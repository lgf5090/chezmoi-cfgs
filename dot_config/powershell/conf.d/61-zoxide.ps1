$homeDir = [Environment]::GetFolderPath('UserProfile')
$zoxideCandidates = @(
    (Join-Path $homeDir '.local/bin/zoxide'),
    (Join-Path $(if ($env:CARGO_HOME) { $env:CARGO_HOME } else { Join-Path $homeDir '.cargo' }) 'bin/zoxide'),
    '/home/linuxbrew/.linuxbrew/bin/zoxide',
    (Join-Path $homeDir '.linuxbrew/bin/zoxide'),
    '/opt/homebrew/bin/zoxide',
    '/usr/local/bin/zoxide',
    '/usr/bin/zoxide'
)

if ($global:ShellsOS -eq 'windows') {
    $zoxideCandidates += @(
        (Join-Path $homeDir 'scoop/shims/zoxide.exe'),
        $(if ($env:PROGRAMDATA) { Join-Path $env:PROGRAMDATA 'scoop/shims/zoxide.exe' }),
        $(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Links/zoxide.exe' })
    )
}

foreach ($candidate in $zoxideCandidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
    $script:PowerShellZoxideExe = (Resolve-Path -LiteralPath $candidate).ProviderPath
    break
}

if ([string]::IsNullOrWhiteSpace($script:PowerShellZoxideExe) -and $env:POWERSHELL_ZOXIDE_DISCOVERY -eq '1') {
    $script:PowerShellZoxideExe = (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue).Source
}

if (-not [string]::IsNullOrWhiteSpace($script:PowerShellZoxideExe)) {
    $zoxideItem = [System.IO.FileInfo]::new($script:PowerShellZoxideExe)
    $zoxideKey = "$($zoxideItem.FullName):$($zoxideItem.LastWriteTimeUtc.Ticks):$($zoxideItem.Length)"
    $cacheRoot = if ([string]::IsNullOrWhiteSpace($env:XDG_CACHE_HOME)) {
        Join-Path $homeDir '.cache'
    } else {
        $env:XDG_CACHE_HOME
    }
    $cacheDir = Join-Path $cacheRoot 'powershell'
    $hash = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($zoxideItem.FullName))
    } finally {
        $hash.Dispose()
    }
    $cacheId = [System.BitConverter]::ToString($hashBytes, 0, 8).Replace('-', '').ToLowerInvariant()
    $cacheFile = Join-Path $cacheDir "zoxide-init-$cacheId.ps1"
    $cacheHeader = "# PowerShellZoxideInitKey=$zoxideKey"

    if ([System.IO.File]::Exists($cacheFile)) {
        $cachedHook = [System.IO.File]::ReadAllText($cacheFile)
        if ($cachedHook.StartsWith($cacheHeader, [System.StringComparison]::Ordinal)) {
            Invoke-Expression $cachedHook
            return
        }
    }

    $hook = & $script:PowerShellZoxideExe init powershell | Out-String
    if ([string]::IsNullOrWhiteSpace($hook)) {
        return
    }

    $cachedHook = "$cacheHeader`n$hook"
    try {
        New-Item -ItemType Directory -Force -Path $cacheDir -ErrorAction Stop | Out-Null
        [System.IO.File]::WriteAllText($cacheFile, $cachedHook, [System.Text.UTF8Encoding]::new($false))
    } catch {
    }
    Invoke-Expression $cachedHook
}
