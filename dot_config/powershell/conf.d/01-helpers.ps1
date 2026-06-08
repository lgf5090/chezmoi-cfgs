function Test-Command {
    param([Parameter(Mandatory)][string]$Name)
    $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function Get-PathComparer {
    if ($script:IsWindowsPlatform) {
        [StringComparer]::OrdinalIgnoreCase
    } else {
        [StringComparer]::Ordinal
    }
}

function Get-PathEntries {
    $current = [Environment]::GetEnvironmentVariable('PATH', 'Process')
    if ([string]::IsNullOrEmpty($current)) {
        return @()
    }
    $current -split [Regex]::Escape([IO.Path]::PathSeparator)
}

function Set-PathEntries {
    param([Parameter(Mandatory)][string[]]$Entries)
    $env:PATH = ($Entries -join [IO.Path]::PathSeparator)
}

function Get-ExistingDirectoryPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }
    if (-not [System.IO.Directory]::Exists($Path)) {
        return $null
    }

    [System.IO.Path]::GetFullPath($Path)
}

function Add-PathPrepend {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Path)

    $entries = [System.Collections.Generic.List[string]]::new()
    $entries.AddRange([string[]](Get-PathEntries))
    $comparer = Get-PathComparer

    foreach ($item in $Path) {
        $resolved = Get-ExistingDirectoryPath -Path $item
        if ([string]::IsNullOrWhiteSpace($resolved)) { continue }
        for ($i = $entries.Count - 1; $i -ge 0; $i--) {
            if ($comparer.Equals($entries[$i], $resolved)) {
                $entries.RemoveAt($i)
            }
        }
        $entries.Insert(0, $resolved)
    }

    Set-PathEntries $entries.ToArray()
}

function Add-PathAppend {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Path)

    $entries = [System.Collections.Generic.List[string]]::new()
    $entries.AddRange([string[]](Get-PathEntries))
    $comparer = Get-PathComparer

    foreach ($item in $Path) {
        $resolved = Get-ExistingDirectoryPath -Path $item
        if ([string]::IsNullOrWhiteSpace($resolved)) { continue }
        for ($i = $entries.Count - 1; $i -ge 0; $i--) {
            if ($comparer.Equals($entries[$i], $resolved)) {
                $entries.RemoveAt($i)
            }
        }
        $entries.Add($resolved)
    }

    Set-PathEntries $entries.ToArray()
}

$global:PowerShellLocalLoaderVersion = 1

function Add-PathPrependValue {
    param([Parameter(Mandatory)][string]$Value)

    $entries = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new((Get-PathComparer))
    $separatorPattern = if ($script:IsWindowsPlatform) { ';' } else { '[:;]' }

    foreach ($item in (($Value -split $separatorPattern) + (Get-PathEntries))) {
        if ([string]::IsNullOrWhiteSpace($item)) { continue }
        $resolved = Get-ExistingDirectoryPath -Path $item
        if ([string]::IsNullOrWhiteSpace($resolved)) { continue }
        if (-not $seen.Add($resolved)) { continue }
        [void]$entries.Add($resolved)
    }

    Set-PathEntries $entries.ToArray()
}

function Import-LocalEnvFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not [System.IO.File]::Exists($Path)) {
        return
    }

    foreach ($lineRaw in [System.IO.File]::ReadLines($Path)) {
        $line = $lineRaw.TrimStart()
        if ([string]::IsNullOrEmpty($line) -or $line[0] -eq '#') {
            continue
        }
        if ($line.StartsWith('export ')) {
            $line = $line.Substring(6).TrimStart()
        }

        $eq = $line.IndexOf('=')
        if ($eq -lt 1) {
            continue
        }

        $key = $line.Substring(0, $eq).TrimEnd()
        $value = $line.Substring($eq + 1).Trim()
        if ($key -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
            continue
        }

        if ($value.Length -ge 2) {
            $first = $value[0]
            $last = $value[$value.Length - 1]
            if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
                $value = $value.Substring(1, $value.Length - 2)
            }
        }

        $value = $value.Replace('{HOME}', $HOME).Replace('{PATH}', $env:PATH)
        if ($key -eq 'PATH') {
            Add-PathPrependValue -Value $value
        } else {
            [System.Environment]::SetEnvironmentVariable($key, $value, 'Process')
        }
    }
}

function Import-LocalAliasFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not [System.IO.File]::Exists($Path)) {
        return
    }

    $item = [System.IO.FileInfo]::new($Path)
    $loadKey = "$($item.FullName):$($item.LastWriteTimeUtc.Ticks):$($item.Length)"
    if ($global:PowerShellLocalAliasesLoadedKey -eq $loadKey) {
        return
    }

    $cacheRoot = if ([string]::IsNullOrWhiteSpace($env:XDG_CACHE_HOME)) {
        Join-Path $HOME '.cache'
    } else {
        $env:XDG_CACHE_HOME
    }
    $cacheDir = Join-Path $cacheRoot 'powershell'
    $hash = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($item.FullName))
    } finally {
        $hash.Dispose()
    }
    $cacheId = [System.BitConverter]::ToString($hashBytes, 0, 8).Replace('-', '').ToLowerInvariant()
    $cacheFile = Join-Path $cacheDir "local-aliases-$cacheId.ps1"
    $cacheHeader = "# PowerShellLocalAliasesLoadedKey=$loadKey"

    if ([System.IO.File]::Exists($cacheFile)) {
        $firstLine = $null
        $reader = [System.IO.File]::OpenText($cacheFile)
        try {
            $firstLine = $reader.ReadLine()
        } finally {
            $reader.Dispose()
        }

        if ($firstLine -eq $cacheHeader) {
            . $cacheFile
            $global:PowerShellLocalAliasesLoadedKey = $loadKey
            return
        }
    }

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine($cacheHeader)

    foreach ($lineRaw in [System.IO.File]::ReadLines($Path)) {
        $line = $lineRaw.TrimStart()
        if ([string]::IsNullOrEmpty($line) -or $line[0] -eq '#') {
            continue
        }

        $eq = $line.IndexOf('=')
        if ($eq -lt 1) {
            continue
        }

        $name = $line.Substring(0, $eq).TrimEnd()
        $body = $line.Substring($eq + 1).Trim()
        if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_-]*$') {
            continue
        }

        if ($body.Length -ge 2) {
            $first = $body[0]
            $last = $body[$body.Length - 1]
            if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
                $body = $body.Substring(1, $body.Length - 2)
            }
        }

        [void]$builder.Append('function global:').Append($name).Append(' { ').Append($body).AppendLine(' @args }')
    }

    $aliasScript = $builder.ToString()
    try {
        New-Item -ItemType Directory -Force -Path $cacheDir -ErrorAction Stop | Out-Null
        [System.IO.File]::WriteAllText($cacheFile, $aliasScript, [System.Text.UTF8Encoding]::new($false))
        . $cacheFile
    } catch {
        . ([scriptblock]::Create($aliasScript))
    }
    $global:PowerShellLocalAliasesLoadedKey = $loadKey
}

function Test-VersionGe {
    param(
        [Parameter(Mandatory)][string]$Left,
        [Parameter(Mandatory)][string]$Right
    )

    $leftParts = $Left -split '\.'
    $rightParts = $Right -split '\.'

    for ($i = 0; $i -lt 3; $i++) {
        $l = if ($i -lt $leftParts.Count) { $leftParts[$i] -replace '[^0-9].*$', '' } else { '0' }
        $r = if ($i -lt $rightParts.Count) { $rightParts[$i] -replace '[^0-9].*$', '' } else { '0' }
        if ([string]::IsNullOrEmpty($l)) { $l = '0' }
        if ([string]::IsNullOrEmpty($r)) { $r = '0' }

        $ln = [int]$l
        $rn = [int]$r
        if ($ln -gt $rn) { return $true }
        if ($ln -lt $rn) { return $false }
    }

    $true
}

if ([string]::IsNullOrWhiteSpace($env:POWERSHELL_PLUGIN_DIR)) {
    $env:POWERSHELL_PLUGIN_DIR = Join-Path $env:XDG_DATA_HOME 'powershell/plugins'
}
if ([string]::IsNullOrWhiteSpace($env:POWERSHELL_PLUGIN_AUTO_INSTALL)) {
    $env:POWERSHELL_PLUGIN_AUTO_INSTALL = '1'
}

if (-not $global:PowerShellLoadedPlugins) {
    $global:PowerShellLoadedPlugins = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
}

function _psplugin {
    param(
        [Parameter(Mandatory)][string]$Owner,
        [Parameter(Mandatory)][string]$Repo
    )

    if ($global:PowerShellLoadedPlugins.Contains($Repo)) {
        return
    }

    $pluginDir = Join-Path $env:POWERSHELL_PLUGIN_DIR $Repo
    if (-not (Test-Path -LiteralPath $pluginDir -PathType Container)) {
        if ($env:POWERSHELL_PLUGIN_AUTO_INSTALL -ne '1') {
            Write-Warning "powershell: plugin missing, skip $Repo"
            return
        }
        if (-not (Test-Command git)) {
            Write-Warning "powershell: git not found, skip $Repo"
            return
        }

        New-Item -ItemType Directory -Force -Path $env:POWERSHELL_PLUGIN_DIR | Out-Null
        git clone --depth=1 "https://github.com/$Owner/$Repo" $pluginDir
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "powershell: failed to install $Repo"
            return
        }
    }

    $module = Get-ChildItem -LiteralPath $pluginDir -Include '*.psd1','*.psm1' -File -Recurse |
        Sort-Object -Property FullName |
        Select-Object -First 1

    if ($module) {
        Import-Module $module.FullName -Global -ErrorAction SilentlyContinue
        [void]$global:PowerShellLoadedPlugins.Add($Repo)
        return
    }

    Write-Warning "powershell: no module entry found for $Repo"
}

function Update-PSPlugin {
    if (-not (Test-Command git)) {
        Write-Warning 'powershell: git not found'
        return
    }
    if (-not (Test-Path -LiteralPath $env:POWERSHELL_PLUGIN_DIR -PathType Container)) {
        return
    }

    Get-ChildItem -LiteralPath $env:POWERSHELL_PLUGIN_DIR -Directory | ForEach-Object {
        if (Test-Path -LiteralPath (Join-Path $_.FullName '.git') -PathType Container) {
            Write-Host "Updating $($_.Name)..."
            git -C $_.FullName pull --ff-only
        }
    }
}
