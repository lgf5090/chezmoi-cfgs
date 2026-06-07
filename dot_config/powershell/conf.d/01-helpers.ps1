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

function Add-PathPrepend {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Path)

    $entries = [System.Collections.Generic.List[string]]::new()
    $entries.AddRange([string[]](Get-PathEntries))
    $comparer = Get-PathComparer

    foreach ($item in $Path) {
        if ([string]::IsNullOrWhiteSpace($item)) { continue }
        if (-not (Test-Path -LiteralPath $item -PathType Container)) { continue }

        $resolved = (Resolve-Path -LiteralPath $item).ProviderPath
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
        if ([string]::IsNullOrWhiteSpace($item)) { continue }
        if (-not (Test-Path -LiteralPath $item -PathType Container)) { continue }

        $resolved = (Resolve-Path -LiteralPath $item).ProviderPath
        for ($i = $entries.Count - 1; $i -ge 0; $i--) {
            if ($comparer.Equals($entries[$i], $resolved)) {
                $entries.RemoveAt($i)
            }
        }
        $entries.Add($resolved)
    }

    Set-PathEntries $entries.ToArray()
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
