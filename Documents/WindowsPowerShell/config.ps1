# Windows PowerShell 5.1 profile config.
# Keep this file independent from dot_config/powershell because that tree targets
# PowerShell 7+ and optional external tools.

$env:POWERSHELL_CONFIG_DIR = $PSScriptRoot
$global:PowerShellConfigDir = [System.IO.Path]::GetFullPath($env:POWERSHELL_CONFIG_DIR)
$global:ShellsOS = 'windows'
$env:SHELLS_OS = 'windows'

$homeDir = [Environment]::GetFolderPath('UserProfile')
if ([string]::IsNullOrWhiteSpace($homeDir)) {
    $homeDir = $HOME
}

if ([string]::IsNullOrWhiteSpace($env:XDG_CONFIG_HOME)) {
    $env:XDG_CONFIG_HOME = [System.IO.Path]::Combine($homeDir, '.config')
}
if ([string]::IsNullOrWhiteSpace($env:XDG_DATA_HOME)) {
    $env:XDG_DATA_HOME = [System.IO.Path]::Combine($homeDir, '.local', 'share')
}
if ([string]::IsNullOrWhiteSpace($env:XDG_STATE_HOME)) {
    $env:XDG_STATE_HOME = [System.IO.Path]::Combine($homeDir, '.local', 'state')
}
if ([string]::IsNullOrWhiteSpace($env:XDG_CACHE_HOME)) {
    $env:XDG_CACHE_HOME = [System.IO.Path]::Combine($homeDir, '.cache')
}

function New-DirectoryIfNeeded {
    param([AllowEmptyString()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    try {
        if (-not [System.IO.Directory]::Exists($Path)) {
            [System.IO.Directory]::CreateDirectory($Path) | Out-Null
        }
        return [System.IO.Directory]::Exists($Path)
    } catch {
        return $false
    }
}

foreach ($dir in @(
    [System.IO.Path]::Combine($env:XDG_STATE_HOME, 'WindowsPowerShell'),
    [System.IO.Path]::Combine($env:XDG_CACHE_HOME, 'WindowsPowerShell')
)) {
    [void](New-DirectoryIfNeeded -Path $dir)
}

function Test-Command {
    param([Parameter(Mandatory)][string]$Name)

    $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function Get-PathComparer {
    [StringComparer]::OrdinalIgnoreCase
}

function Get-PathEntries {
    $current = [Environment]::GetEnvironmentVariable('PATH', 'Process')
    if ([string]::IsNullOrWhiteSpace($current)) {
        return @()
    }

    foreach ($entry in ($current -split [Regex]::Escape([IO.Path]::PathSeparator))) {
        if ([string]::IsNullOrWhiteSpace($entry)) { continue }
        $entry
    }
}

function Set-PathEntries {
    param([AllowEmptyCollection()][AllowEmptyString()][string[]]$Entries = @())

    $cleanEntries = foreach ($entry in $Entries) {
        if ([string]::IsNullOrWhiteSpace($entry)) { continue }
        $entry
    }

    $env:PATH = ($cleanEntries -join [IO.Path]::PathSeparator)
}

function Get-ExistingDirectoryPath {
    param([AllowEmptyString()][string]$Path)

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

    $entries = New-Object 'System.Collections.Generic.List[string]'
    $entries.AddRange([string[]]@(Get-PathEntries))
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

    $entries = New-Object 'System.Collections.Generic.List[string]'
    $entries.AddRange([string[]]@(Get-PathEntries))
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

function Add-PathPrependValue {
    param([Parameter(Mandatory)][string]$Value)

    $entries = New-Object 'System.Collections.Generic.List[string]'
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' (Get-PathComparer)

    foreach ($item in (($Value -split ';') + @(Get-PathEntries))) {
        if ([string]::IsNullOrWhiteSpace($item)) { continue }
        $resolved = Get-ExistingDirectoryPath -Path $item
        if ([string]::IsNullOrWhiteSpace($resolved)) { continue }
        if (-not $seen.Add($resolved)) { continue }
        [void]$entries.Add($resolved)
    }

    Set-PathEntries $entries.ToArray()
}

function Set-ProcessEnvIfEmpty {
    param(
        [Parameter(Mandatory)][string]$Name,
        [AllowEmptyString()][string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }
    if (-not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($Name, 'Process'))) {
        return
    }

    [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
}

function Get-FirstExistingDirectory {
    param([AllowEmptyCollection()][AllowEmptyString()][string[]]$Path = @())

    foreach ($candidate in $Path) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        if (-not [System.IO.Directory]::Exists($candidate)) { continue }
        return [System.IO.Path]::GetFullPath($candidate)
    }

    $null
}

function Set-ProcessEnvFirstExistingDirectory {
    param(
        [Parameter(Mandatory)][string]$Name,
        [AllowEmptyCollection()][AllowEmptyString()][string[]]$Path = @()
    )

    if (-not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($Name, 'Process'))) {
        return
    }

    $dir = Get-FirstExistingDirectory -Path $Path
    if ([string]::IsNullOrWhiteSpace($dir)) {
        return
    }

    [Environment]::SetEnvironmentVariable($Name, $dir, 'Process')
}

function Get-LatestChildDirectory {
    param(
        [AllowEmptyString()][string]$Path,
        [AllowEmptyString()][string]$Filter = '*'
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }
    if (-not [System.IO.Directory]::Exists($Path)) {
        return $null
    }

    $item = Get-ChildItem -LiteralPath $Path -Directory -Filter $Filter -ErrorAction SilentlyContinue |
        Sort-Object -Property Name -Descending |
        Select-Object -First 1
    if (-not $item) {
        return $null
    }

    $item.FullName
}

if ([string]::IsNullOrWhiteSpace($env:EDITOR)) {
    $env:EDITOR = 'notepad.exe'
}
if ([string]::IsNullOrWhiteSpace($env:VISUAL)) {
    $env:VISUAL = $env:EDITOR
}
if ([string]::IsNullOrWhiteSpace($env:CLICOLOR)) {
    $env:CLICOLOR = '1'
}

$localEnvFile = if ([string]::IsNullOrWhiteSpace($env:POWERSHELL_LOCAL_ENVS_FILE)) {
    [System.IO.Path]::Combine($homeDir, '.envs')
} else {
    $env:POWERSHELL_LOCAL_ENVS_FILE
}

if ([System.IO.File]::Exists($localEnvFile)) {
    foreach ($lineRaw in [System.IO.File]::ReadLines($localEnvFile)) {
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

        $value = $value.Replace('{HOME}', $homeDir).Replace('{PATH}', $env:PATH)
        if ($key -eq 'PATH') {
            Add-PathPrependValue -Value $value
        } else {
            [Environment]::SetEnvironmentVariable($key, $value, 'Process')
        }
    }
}

function Import-LocalAliasFile {
    param([AllowEmptyString()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }
    if (-not [System.IO.File]::Exists($Path)) {
        return
    }

    $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $item) {
        return
    }

    $loadKey = "$($item.FullName):$($item.LastWriteTimeUtc.Ticks):$($item.Length)"
    if ($global:WindowsPowerShellLocalAliasesLoadedKey -eq $loadKey) {
        return
    }

    foreach ($lineRaw in [System.IO.File]::ReadLines($item.FullName)) {
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

        try {
            . ([scriptblock]::Create("function global:$name { $body @args }"))
        } catch {
            if ($env:POWERSHELL_ALIAS_WARNINGS -eq '1') {
                Write-Warning "WindowsPowerShell: skip invalid alias $name"
            }
        }
    }

    $global:WindowsPowerShellLocalAliasesLoadedKey = $loadKey
}

$programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)', 'Process')

Set-ProcessEnvIfEmpty -Name 'NPM_CONFIG_PREFIX' -Value ([System.IO.Path]::Combine($homeDir, '.npm-global'))
Set-ProcessEnvIfEmpty -Name 'PNPM_HOME' -Value ([System.IO.Path]::Combine($homeDir, '.pnpm-global'))
Set-ProcessEnvIfEmpty -Name 'MISE_DATA_DIR' -Value ([System.IO.Path]::Combine($env:XDG_DATA_HOME, 'mise'))
Set-ProcessEnvIfEmpty -Name 'GOPATH' -Value ([System.IO.Path]::Combine($homeDir, 'go'))
Set-ProcessEnvIfEmpty -Name 'NVM_DIR' -Value ([System.IO.Path]::Combine($homeDir, '.nvm'))
Set-ProcessEnvIfEmpty -Name 'SDKMAN_DIR' -Value ([System.IO.Path]::Combine($homeDir, '.sdkman'))
Set-ProcessEnvIfEmpty -Name 'DOCKER_BUILDKIT' -Value '1'
Set-ProcessEnvIfEmpty -Name 'COMPOSE_DOCKER_CLI_BUILD' -Value '1'

Set-ProcessEnvFirstExistingDirectory -Name 'FNM_DIR' -Path @(
    [System.IO.Path]::Combine($env:XDG_DATA_HOME, 'fnm'),
    [System.IO.Path]::Combine($homeDir, '.fnm')
)
Set-ProcessEnvFirstExistingDirectory -Name 'VOLTA_HOME' -Path @(
    [System.IO.Path]::Combine($homeDir, '.volta')
)
Set-ProcessEnvFirstExistingDirectory -Name 'BUN_INSTALL' -Path @(
    [System.IO.Path]::Combine($homeDir, '.bun')
)
Set-ProcessEnvFirstExistingDirectory -Name 'DENO_INSTALL' -Path @(
    [System.IO.Path]::Combine($homeDir, '.deno')
)
Set-ProcessEnvFirstExistingDirectory -Name 'GOROOT' -Path @(
    [System.IO.Path]::Combine($homeDir, '.local', 'go'),
    $(if ($env:LOCALAPPDATA) { [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Programs', 'Go') }),
    $(if ($env:ProgramFiles) { [System.IO.Path]::Combine($env:ProgramFiles, 'Go') }),
    $(if ($programFilesX86) { [System.IO.Path]::Combine($programFilesX86, 'Go') }),
    'C:\Go'
)
Set-ProcessEnvFirstExistingDirectory -Name 'ANACONDA_HOME' -Path @(
    [System.IO.Path]::Combine($homeDir, 'anaconda3'),
    [System.IO.Path]::Combine($homeDir, 'miniconda3'),
    $(if ($env:LOCALAPPDATA) { [System.IO.Path]::Combine($env:LOCALAPPDATA, 'anaconda3') }),
    $(if ($env:LOCALAPPDATA) { [System.IO.Path]::Combine($env:LOCALAPPDATA, 'miniconda3') }),
    $(if ($env:PROGRAMDATA) { [System.IO.Path]::Combine($env:PROGRAMDATA, 'anaconda3') }),
    $(if ($env:PROGRAMDATA) { [System.IO.Path]::Combine($env:PROGRAMDATA, 'miniconda3') })
)
Set-ProcessEnvFirstExistingDirectory -Name 'POETRY_HOME' -Path @(
    [System.IO.Path]::Combine($homeDir, '.poetry')
)
Set-ProcessEnvFirstExistingDirectory -Name 'PYENV_ROOT' -Path @(
    [System.IO.Path]::Combine($homeDir, '.pyenv', 'pyenv-win'),
    [System.IO.Path]::Combine($homeDir, '.pyenv')
)
Set-ProcessEnvFirstExistingDirectory -Name 'ASDF_DIR' -Path @(
    [System.IO.Path]::Combine($homeDir, '.asdf')
)

if ([string]::IsNullOrWhiteSpace($env:ASDF_DATA_DIR) -and -not [string]::IsNullOrWhiteSpace($env:ASDF_DIR)) {
    if ((Get-PathComparer).Equals($env:ASDF_DIR, [System.IO.Path]::Combine($homeDir, '.asdf'))) {
        $env:ASDF_DATA_DIR = $env:ASDF_DIR
    } else {
        $env:ASDF_DATA_DIR = [System.IO.Path]::Combine($env:XDG_DATA_HOME, 'asdf')
    }
}

foreach ($spec in @(
    @('RBENV_ROOT', [System.IO.Path]::Combine($homeDir, '.rbenv')),
    @('NODENV_ROOT', [System.IO.Path]::Combine($homeDir, '.nodenv')),
    @('GOENV_ROOT', [System.IO.Path]::Combine($homeDir, '.goenv')),
    @('JENV_ROOT', [System.IO.Path]::Combine($homeDir, '.jenv'))
)) {
    Set-ProcessEnvFirstExistingDirectory -Name $spec[0] -Path @($spec[1])
}

Set-ProcessEnvFirstExistingDirectory -Name 'NVM_HOME' -Path @(
    $(if ($env:APPDATA) { [System.IO.Path]::Combine($env:APPDATA, 'nvm') }),
    [System.IO.Path]::Combine($homeDir, 'scoop', 'apps', 'nvm', 'current'),
    [System.IO.Path]::Combine($homeDir, '.nvm')
)
Set-ProcessEnvFirstExistingDirectory -Name 'NVM_SYMLINK' -Path @(
    $(if ($env:ProgramFiles) { [System.IO.Path]::Combine($env:ProgramFiles, 'nodejs') }),
    [System.IO.Path]::Combine($homeDir, 'scoop', 'apps', 'nodejs', 'current')
)

if ([string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
    $javaCandidates = @(
        $(if ($env:ProgramFiles) { [System.IO.Path]::Combine($env:ProgramFiles, 'Java') }),
        $(if ($env:ProgramFiles) { [System.IO.Path]::Combine($env:ProgramFiles, 'Eclipse Adoptium') }),
        $(if ($env:ProgramFiles) { [System.IO.Path]::Combine($env:ProgramFiles, 'Microsoft') }),
        $(if ($env:ProgramFiles) { [System.IO.Path]::Combine($env:ProgramFiles, 'Zulu') })
    )

    foreach ($javaRoot in $javaCandidates) {
        $javaHome = Get-LatestChildDirectory -Path $javaRoot -Filter 'jdk*'
        if ([string]::IsNullOrWhiteSpace($javaHome)) { continue }
        $env:JAVA_HOME = $javaHome
        break
    }
}

$lfIcons = [System.IO.Path]::Combine($env:XDG_CONFIG_HOME, 'lf', 'icons')
if ([System.IO.File]::Exists($lfIcons)) {
    $env:LF_ICONS = ((Get-Content -LiteralPath $lfIcons) -join ':') + ':'
}
Remove-Variable programFilesX86, lfIcons -ErrorAction SilentlyContinue

$cargoHome = if ([string]::IsNullOrWhiteSpace($env:CARGO_HOME)) {
    [System.IO.Path]::Combine($homeDir, '.cargo')
} else {
    $env:CARGO_HOME
}

$pathAppend = @(
    [System.IO.Path]::Combine($homeDir, '.lmstudio', 'bin'),
    [System.IO.Path]::Combine($homeDir, '.mimocode', 'bin'),
    [System.IO.Path]::Combine($homeDir, '.local', 'bin'),
    [System.IO.Path]::Combine($homeDir, 'bin'),
    [System.IO.Path]::Combine($homeDir, 'Applications'),
    [System.IO.Path]::Combine($homeDir, '.local', 'Applications')
)

$pathPrepend = @(
    $(if ($env:ASDF_DIR) { [System.IO.Path]::Combine($env:ASDF_DIR, 'bin') }),
    $(if ($env:RBENV_ROOT) { [System.IO.Path]::Combine($env:RBENV_ROOT, 'bin') }),
    $(if ($env:NODENV_ROOT) { [System.IO.Path]::Combine($env:NODENV_ROOT, 'bin') }),
    $(if ($env:GOENV_ROOT) { [System.IO.Path]::Combine($env:GOENV_ROOT, 'bin') }),
    $(if ($env:JENV_ROOT) { [System.IO.Path]::Combine($env:JENV_ROOT, 'bin') }),
    [System.IO.Path]::Combine($cargoHome, 'bin'),
    [System.IO.Path]::Combine($homeDir, '.rd', 'bin'),
    [System.IO.Path]::Combine($homeDir, '.opencode', 'bin'),
    $(if ($env:BUN_INSTALL) { [System.IO.Path]::Combine($env:BUN_INSTALL, 'bin') }),
    $(if ($env:DENO_INSTALL) { [System.IO.Path]::Combine($env:DENO_INSTALL, 'bin') }),
    $(if ($env:NPM_CONFIG_PREFIX) { [System.IO.Path]::Combine($env:NPM_CONFIG_PREFIX, 'bin') }),
    $(if ($env:PNPM_HOME) { $env:PNPM_HOME }),
    [System.IO.Path]::Combine($homeDir, '.yarn', 'bin'),
    [System.IO.Path]::Combine($homeDir, '.config', 'yarn', 'global', 'node_modules', '.bin'),
    $(if ($env:VOLTA_HOME) { [System.IO.Path]::Combine($env:VOLTA_HOME, 'bin') }),
    [System.IO.Path]::Combine($homeDir, '.volta', 'bin'),
    $(if ($env:FNM_DIR) { $env:FNM_DIR }),
    [System.IO.Path]::Combine($homeDir, '.local', 'share', 'npm', 'bin'),
    $(if ($env:PYENV_ROOT) { [System.IO.Path]::Combine($env:PYENV_ROOT, 'bin') }),
    $(if ($env:ANACONDA_HOME) { [System.IO.Path]::Combine($env:ANACONDA_HOME, 'bin') }),
    $(if ($env:ANACONDA_HOME) { [System.IO.Path]::Combine($env:ANACONDA_HOME, 'Scripts') }),
    $(if ($env:ANACONDA_HOME) { [System.IO.Path]::Combine($env:ANACONDA_HOME, 'condabin') }),
    $(if ($env:POETRY_HOME) { [System.IO.Path]::Combine($env:POETRY_HOME, 'bin') }),
    [System.IO.Path]::Combine($homeDir, '.poetry', 'bin'),
    [System.IO.Path]::Combine($homeDir, '.local', 'pipx', 'bin'),
    $(if ($env:GOPATH) { [System.IO.Path]::Combine($env:GOPATH, 'bin') }),
    $(if ($env:GOROOT) { [System.IO.Path]::Combine($env:GOROOT, 'bin') }),
    [System.IO.Path]::Combine($homeDir, '.local', 'bin'),
    [System.IO.Path]::Combine($homeDir, 'bin'),
    [System.IO.Path]::Combine($homeDir, 'scoop', 'shims'),
    $(if ($env:PROGRAMDATA) { [System.IO.Path]::Combine($env:PROGRAMDATA, 'scoop', 'shims') }),
    $(if ($env:PROGRAMDATA) { [System.IO.Path]::Combine($env:PROGRAMDATA, 'chocolatey', 'bin') }),
    $(if ($env:LOCALAPPDATA) { [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'WindowsApps') }),
    $(if ($env:APPDATA) { [System.IO.Path]::Combine($env:APPDATA, 'npm') }),
    [System.IO.Path]::Combine($homeDir, '.nix-profile', 'bin'),
    [System.IO.Path]::Combine($homeDir, '.mise', 'shims'),
    $(if ($env:MISE_DATA_DIR) { [System.IO.Path]::Combine($env:MISE_DATA_DIR, 'shims') }),
    $(if ($env:ASDF_DATA_DIR) { [System.IO.Path]::Combine($env:ASDF_DATA_DIR, 'shims') }),
    $(if ($env:PYENV_ROOT) { [System.IO.Path]::Combine($env:PYENV_ROOT, 'shims') }),
    $(if ($env:PYENV_ROOT) { [System.IO.Path]::Combine($env:PYENV_ROOT, 'pyenv-win', 'bin') }),
    $(if ($env:PYENV_ROOT) { [System.IO.Path]::Combine($env:PYENV_ROOT, 'pyenv-win', 'shims') }),
    $(if ($env:FNM_DIR) { [System.IO.Path]::Combine($env:FNM_DIR, 'aliases', 'default', 'bin') }),
    $(if ($env:NVM_HOME) { $env:NVM_HOME }),
    $(if ($env:NVM_SYMLINK) { $env:NVM_SYMLINK }),
    $(if ($env:JAVA_HOME) { [System.IO.Path]::Combine($env:JAVA_HOME, 'bin') }),
    $(if ($env:RBENV_ROOT) { [System.IO.Path]::Combine($env:RBENV_ROOT, 'shims') }),
    $(if ($env:NODENV_ROOT) { [System.IO.Path]::Combine($env:NODENV_ROOT, 'shims') }),
    $(if ($env:GOENV_ROOT) { [System.IO.Path]::Combine($env:GOENV_ROOT, 'shims') }),
    $(if ($env:JENV_ROOT) { [System.IO.Path]::Combine($env:JENV_ROOT, 'shims') })
)
Add-PathAppend @pathAppend
Add-PathPrepend @pathPrepend

$cargoEnv = [System.IO.Path]::Combine($homeDir, '.cargo', 'env.ps1')
if ($env:POWERSHELL_SOURCE_CARGO_ENV -eq '1' -and [System.IO.File]::Exists($cargoEnv)) {
    . $cargoEnv
}

Remove-Variable pathAppend, pathPrepend, cargoHome, cargoEnv -ErrorAction SilentlyContinue

$loadPSReadLine = (
    $env:POWERSHELL_LOAD_PSREADLINE -eq '1' -or (
        $env:POWERSHELL_LOAD_PSREADLINE -ne '0' -and
        -not [Console]::IsInputRedirected -and
        -not [Console]::IsOutputRedirected
    )
)

$global:PowerShellPSReadLineLoaded = $false
if ($loadPSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
}

if ($loadPSReadLine -and (Get-Module -Name PSReadLine)) {
    $global:PowerShellPSReadLineLoaded = $true
    $historyDir = [System.IO.Path]::Combine($env:XDG_STATE_HOME, 'WindowsPowerShell')
    $historyFile = if (New-DirectoryIfNeeded -Path $historyDir) {
        [System.IO.Path]::Combine($historyDir, 'PSReadLineHistory.txt')
    } else {
        $null
    }

    $psrlOptionCommand = Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue
    if ($psrlOptionCommand) {
        $psrlOptionParameters = $psrlOptionCommand.Parameters

        function Set-PSReadLineOptionIfSupported {
            param(
                [Parameter(Mandatory)][string]$Name,
                [Parameter(Mandatory)]$Value,
                [Parameter(Mandatory)]$Parameters
            )

            if (-not $Parameters.ContainsKey($Name)) { return }
            $option = @{}
            $option[$Name] = $Value
            try {
                Set-PSReadLineOption @option -ErrorAction Stop
            } catch {
            }
        }

        Set-PSReadLineOptionIfSupported -Name 'EditMode' -Value 'Vi' -Parameters $psrlOptionParameters
        Set-PSReadLineOptionIfSupported -Name 'BellStyle' -Value 'None' -Parameters $psrlOptionParameters
        Set-PSReadLineOptionIfSupported -Name 'HistoryNoDuplicates' -Value $true -Parameters $psrlOptionParameters
        Set-PSReadLineOptionIfSupported -Name 'HistorySearchCursorMovesToEnd' -Value $true -Parameters $psrlOptionParameters
        Set-PSReadLineOptionIfSupported -Name 'MaximumHistoryCount' -Value 10000 -Parameters $psrlOptionParameters
        Set-PSReadLineOptionIfSupported -Name 'HistorySaveStyle' -Value 'SaveIncrementally' -Parameters $psrlOptionParameters
        if (-not [string]::IsNullOrWhiteSpace($historyFile)) {
            Set-PSReadLineOptionIfSupported -Name 'HistorySavePath' -Value $historyFile -Parameters $psrlOptionParameters
        }

        if ($psrlOptionParameters.ContainsKey('AddToHistoryHandler')) {
            try {
                Set-PSReadLineOption -AddToHistoryHandler {
                    param($line)

                    if ($line -match '(?i)(password|secret|token|api[_-]?key)\s*[=:]') {
                        return 'MemoryOnly'
                    }

                    'MemoryAndFile'
                } -ErrorAction Stop
            } catch {
            }
        }
    }

    $psrlKeyCommand = Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue
    if ($psrlKeyCommand) {
        $psrlKeyParameters = $psrlKeyCommand.Parameters
        $editMode = $null
        try {
            $editMode = (Get-PSReadLineOption).EditMode
        } catch {
        }
        $useViMode = $psrlKeyParameters.ContainsKey('ViMode') -and "$editMode" -eq 'Vi'

        function Set-PSReadLineKeyIfSupported {
            param(
                [Parameter(Mandatory)][string]$Chord,
                [Parameter(Mandatory)][string]$Function,
                [string]$ViMode,
                [Parameter(Mandatory)][bool]$UseViMode
            )

            $keyArgs = @{
                Chord = $Chord
                Function = $Function
            }
            if ($UseViMode -and -not [string]::IsNullOrWhiteSpace($ViMode)) {
                $keyArgs['ViMode'] = $ViMode
            }
            try {
                Set-PSReadLineKeyHandler @keyArgs -ErrorAction Stop
            } catch {
            }
        }

        $insertKeys = [ordered]@{
            'Ctrl+a'         = 'BeginningOfLine'
            'Ctrl+e'         = 'EndOfLine'
            'Ctrl+b'         = 'BackwardChar'
            'Ctrl+d'         = 'DeleteChar'
            'Ctrl+h'         = 'BackwardDeleteChar'
            'Ctrl+k'         = 'ForwardDeleteLine'
            'Ctrl+u'         = 'BackwardDeleteLine'
            'Ctrl+w'         = 'BackwardKillWord'
            'Ctrl+y'         = 'Yank'
            'Ctrl+r'         = 'ReverseSearchHistory'
            'Ctrl+p'         = 'PreviousHistory'
            'Ctrl+n'         = 'NextHistory'
            'Ctrl+l'         = 'ClearScreen'
            'Alt+f'          = 'ForwardWord'
            'Alt+b'          = 'BackwardWord'
            'Alt+d'          = 'KillWord'
            'Alt+Backspace'  = 'BackwardKillWord'
            'Alt+.'          = 'YankLastArg'
            'Tab'            = 'Complete'
            'UpArrow'        = 'HistorySearchBackward'
            'DownArrow'      = 'HistorySearchForward'
            'Home'           = 'BeginningOfLine'
            'End'            = 'EndOfLine'
            'Delete'         = 'DeleteChar'
            'Ctrl+LeftArrow' = 'BackwardWord'
            'Ctrl+RightArrow' = 'ForwardWord'
        }

        foreach ($entry in $insertKeys.GetEnumerator()) {
            Set-PSReadLineKeyIfSupported -Chord $entry.Key -Function $entry.Value -ViMode 'Insert' -UseViMode $useViMode
        }

        if ($useViMode) {
            $commandKeys = [ordered]@{
                'Ctrl+a'         = 'BeginningOfLine'
                'Ctrl+e'         = 'EndOfLine'
                'Ctrl+b'         = 'BackwardChar'
                'Ctrl+d'         = 'DeleteChar'
                'Ctrl+k'         = 'ForwardDeleteLine'
                'Ctrl+u'         = 'BackwardDeleteLine'
                'Ctrl+w'         = 'BackwardKillWord'
                'Ctrl+y'         = 'Yank'
                'Ctrl+r'         = 'ReverseSearchHistory'
                'Ctrl+p'         = 'PreviousHistory'
                'Ctrl+n'         = 'NextHistory'
                'Ctrl+l'         = 'ClearScreen'
                'g,g'            = 'BeginningOfHistory'
                'G'              = 'EndOfHistory'
                'v'              = 'ViEditVisually'
                'Alt+f'          = 'ForwardWord'
                'Alt+b'          = 'BackwardWord'
                '~'              = 'InvertCase'
                'UpArrow'        = 'PreviousHistory'
                'DownArrow'      = 'NextHistory'
                'Home'           = 'BeginningOfLine'
                'End'            = 'EndOfLine'
                'Delete'         = 'DeleteChar'
                'Ctrl+LeftArrow' = 'BackwardWord'
                'Ctrl+RightArrow' = 'ForwardWord'
            }

            foreach ($entry in $commandKeys.GetEnumerator()) {
                Set-PSReadLineKeyIfSupported -Chord $entry.Key -Function $entry.Value -ViMode 'Command' -UseViMode $true
            }
        }

        Remove-Variable insertKeys, commandKeys, useViMode, editMode, psrlKeyParameters, psrlKeyCommand -ErrorAction SilentlyContinue
    }

    Remove-Variable historyDir, historyFile, psrlOptionCommand, psrlOptionParameters -ErrorAction SilentlyContinue
}

function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }
function l { Get-ChildItem @args }
function lt { Get-ChildItem -Force @args | Sort-Object -Property LastWriteTime -Descending }

function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

function mkdirp {
    param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Path)

    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function now { Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz' }
function reload { . (Join-Path $global:PowerShellConfigDir 'config.ps1') }

function grep {
    param(
        [Parameter(Position=0, Mandatory)][string]$Pattern,
        [Parameter(ValueFromRemainingArguments)][string[]]$Path
    )

    Select-String -Pattern $Pattern -Path ($(if ($Path) { $Path } else { '*' }))
}

function mkcd {
    param([Parameter(Position=0)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Error 'usage: mkcd <dir>'
        return
    }

    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Location -LiteralPath $Path
}

function paths {
    Get-PathEntries
}

function proxy {
    param(
        [Parameter(Position=0)][string]$HostName,
        [Parameter(Position=1)][string]$Port
    )

    if ([string]::IsNullOrWhiteSpace($HostName)) {
        $HostName = if ($env:PROXY_HOST) { $env:PROXY_HOST } else { '127.0.0.1' }
    }
    if ([string]::IsNullOrWhiteSpace($Port)) {
        $Port = if ($env:PROXY_PORT) { $env:PROXY_PORT } else { '3067' }
    }

    $url = "http://${HostName}:${Port}"
    $env:http_proxy = $url
    $env:https_proxy = $url
    $env:HTTP_PROXY = $url
    $env:HTTPS_PROXY = $url
    "proxy on (${HostName}:${Port})"
}

function socks5 {
    param(
        [Parameter(Position=0)][string]$HostName,
        [Parameter(Position=1)][string]$Port
    )

    if ([string]::IsNullOrWhiteSpace($HostName)) {
        $HostName = if ($env:PROXY_HOST) { $env:PROXY_HOST } else { '127.0.0.1' }
    }
    if ([string]::IsNullOrWhiteSpace($Port)) {
        $Port = if ($env:PROXY_PORT) { $env:PROXY_PORT } else { '3067' }
    }

    $url = "socks5://${HostName}:${Port}"
    $env:all_proxy = $url
    $env:ALL_PROXY = $url
    "socks5 on (${HostName}:${Port})"
}

function unproxy {
    Remove-Item Env:http_proxy,Env:https_proxy,Env:HTTP_PROXY,Env:HTTPS_PROXY,Env:all_proxy,Env:ALL_PROXY -ErrorAction SilentlyContinue
    'proxy off'
}

function proxyinfo {
    "http : $(if ($env:http_proxy) { $env:http_proxy } else { 'unset' })"
    "https: $(if ($env:https_proxy) { $env:https_proxy } else { 'unset' })"
    "socks: $(if ($env:all_proxy) { $env:all_proxy } else { 'unset' })"
}

function Show-UuidHelp {
    @'
usage:
  uuid
  uuid -n COUNT
  uuid -h | --help

Generate RFC 4122 version 4 UUIDs using PowerShell built-in language features.
'@
}

function uuid {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $count = 1
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        $arg = $Arguments[$i]
        switch ($arg) {
            { $_ -in @('-h', '--help') } {
                Show-UuidHelp
                return
            }
            { $_ -in @('-n', '--count') } {
                if (++$i -ge $Arguments.Count -or -not [int]::TryParse($Arguments[$i], [ref]$count) -or $count -lt 1) {
                    throw "uuid: $arg requires a positive integer"
                }
                continue
            }
            '--' {
                if ($i + 1 -lt $Arguments.Count) {
                    throw "uuid: unexpected argument: $($Arguments[$i + 1])"
                }
                continue
            }
            default {
                if ($arg.StartsWith('-')) {
                    throw "uuid: unknown option: $arg"
                }
                throw "uuid: unexpected argument: $arg"
            }
        }
    }

    for ($i = 0; $i -lt $count; $i++) {
        [guid]::NewGuid().ToString()
    }
}

function Show-RandstrHelp {
    @'
usage:
  randstr [LENGTH] [COUNT]
  randstr -l LENGTH -n COUNT [options]
  randstr -h | --help

Generate random strings using PowerShell built-in language features.

options:
  -l, --length N        characters per string, default: 16
  -n, --count N         number of strings, default: 1
  --lower               use a-z
  --upper               use A-Z
  --alpha               use A-Za-z
  --digits              use 0-9
  --alnum               use A-Za-z0-9, default
  --hex                 use 0-9a-f
  --safe                use A-Za-z0-9_-
  --symbols             use shell-friendly symbols
  --alphabet CHARS      use a custom character set
  --prefix TEXT         prepend TEXT to each string
  --suffix TEXT         append TEXT to each string
'@
}

function ConvertTo-RandstrPositiveInt {
    param(
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$Label
    )

    $number = 0
    if (-not [int]::TryParse($Value, [ref]$number) -or $number -lt 1) {
        throw "randstr: $Label requires a positive integer"
    }
    $number
}

function New-RandstrString {
    param(
        [Parameter(Mandatory)][int]$Length,
        [Parameter(Mandatory)][string]$Alphabet,
        [string]$Prefix = '',
        [string]$Suffix = ''
    )

    $builder = New-Object System.Text.StringBuilder
    $bytes = New-Object byte[] 4
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        for ($i = 0; $i -lt $Length; $i++) {
            $rng.GetBytes($bytes)
            $index = [int]([BitConverter]::ToUInt32($bytes, 0) % [uint32]$Alphabet.Length)
            [void]$builder.Append($Alphabet[$index])
        }
    } finally {
        $rng.Dispose()
    }

    "$Prefix$($builder.ToString())$Suffix"
}

function randstr {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $length = 16
    $count = 1
    $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    $prefix = ''
    $suffix = ''
    $positionals = New-Object 'System.Collections.Generic.List[string]'

    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        $arg = $Arguments[$i]
        switch ($arg) {
            { $_ -in @('-h', '--help') } {
                Show-RandstrHelp
                return
            }
            { $_ -in @('-l', '--length') } {
                if (++$i -ge $Arguments.Count) { throw "randstr: $arg requires a positive integer" }
                $length = ConvertTo-RandstrPositiveInt -Value $Arguments[$i] -Label $arg
                continue
            }
            { $_ -in @('-n', '--count') } {
                if (++$i -ge $Arguments.Count) { throw "randstr: $arg requires a positive integer" }
                $count = ConvertTo-RandstrPositiveInt -Value $Arguments[$i] -Label $arg
                continue
            }
            '--lower' { $alphabet = 'abcdefghijklmnopqrstuvwxyz'; continue }
            '--upper' { $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'; continue }
            '--alpha' { $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'; continue }
            '--digits' { $alphabet = '0123456789'; continue }
            '--alnum' { $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'; continue }
            '--hex' { $alphabet = '0123456789abcdef'; continue }
            '--safe' { $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-'; continue }
            '--symbols' { $alphabet = '!#$%&()*+,-./:;<=>?@[]^_{|}~'; continue }
            '--alphabet' {
                if (++$i -ge $Arguments.Count -or [string]::IsNullOrEmpty($Arguments[$i])) {
                    throw 'randstr: --alphabet requires CHARS'
                }
                $alphabet = $Arguments[$i]
                continue
            }
            '--prefix' {
                if (++$i -ge $Arguments.Count) { throw 'randstr: --prefix requires TEXT' }
                $prefix = $Arguments[$i]
                continue
            }
            '--suffix' {
                if (++$i -ge $Arguments.Count) { throw 'randstr: --suffix requires TEXT' }
                $suffix = $Arguments[$i]
                continue
            }
            '--' {
                for ($j = $i + 1; $j -lt $Arguments.Count; $j++) {
                    if ($positionals.Count -eq 0) {
                        $length = ConvertTo-RandstrPositiveInt -Value $Arguments[$j] -Label 'LENGTH'
                    } elseif ($positionals.Count -eq 1) {
                        $count = ConvertTo-RandstrPositiveInt -Value $Arguments[$j] -Label 'COUNT'
                    } else {
                        throw "randstr: unexpected argument: $($Arguments[$j])"
                    }
                    $positionals.Add($Arguments[$j])
                }
                $i = $Arguments.Count
                continue
            }
            default {
                if ($arg.StartsWith('-')) { throw "randstr: unknown option: $arg" }
                if ($positionals.Count -eq 0) {
                    $length = ConvertTo-RandstrPositiveInt -Value $arg -Label 'LENGTH'
                } elseif ($positionals.Count -eq 1) {
                    $count = ConvertTo-RandstrPositiveInt -Value $arg -Label 'COUNT'
                } else {
                    throw "randstr: unexpected argument: $arg"
                }
                $positionals.Add($arg)
            }
        }
    }

    if ([string]::IsNullOrEmpty($alphabet)) {
        throw 'randstr: alphabet must not be empty'
    }

    for ($i = 0; $i -lt $count; $i++) {
        New-RandstrString -Length $length -Alphabet $alphabet -Prefix $prefix -Suffix $suffix
    }
}

Register-ArgumentCompleter -CommandName uuid -ParameterName Arguments -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    @('-h', '--help', '-n', '--count') |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_
        }
}

Register-ArgumentCompleter -CommandName randstr -ParameterName Arguments -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    @(
        '-h', '--help', '-l', '--length', '-n', '--count',
        '--lower', '--upper', '--alpha', '--digits', '--alnum',
        '--hex', '--safe', '--symbols', '--alphabet', '--prefix', '--suffix'
    ) |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_
        }
}

Register-ArgumentCompleter -CommandName mkcd -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    Get-ChildItem -Directory -Path "$wordToComplete*" -ErrorAction SilentlyContinue |
        ForEach-Object {
            New-Object System.Management.Automation.CompletionResult $_.FullName, $_.Name, 'ProviderContainer', $_.FullName
        }
}

$script:PromptHostName = try {
    [Net.Dns]::GetHostName()
} catch {
    [Environment]::MachineName
}

$script:PromptUseAnsi = (
    -not [Console]::IsOutputRedirected -and
    [string]::IsNullOrWhiteSpace($env:NO_COLOR)
)
$script:PromptEsc = [char]27
$script:AnsiReset = if ($script:PromptUseAnsi) { "$script:PromptEsc[0m" } else { '' }
$script:AnsiGray = if ($script:PromptUseAnsi) { "$script:PromptEsc[90m" } else { '' }
$script:AnsiWhite = if ($script:PromptUseAnsi) { "$script:PromptEsc[97m" } else { '' }
$script:AnsiRed = if ($script:PromptUseAnsi) { "$script:PromptEsc[31m" } else { '' }
$script:AnsiGreen = if ($script:PromptUseAnsi) { "$script:PromptEsc[32m" } else { '' }
$script:AnsiBlue = if ($script:PromptUseAnsi) { "$script:PromptEsc[34m" } else { '' }
$script:AnsiMagenta = if ($script:PromptUseAnsi) { "$script:PromptEsc[35m" } else { '' }
$script:AnsiCyan = if ($script:PromptUseAnsi) { "$script:PromptEsc[36m" } else { '' }

function Get-PromptGitDirectory {
    param([AllowEmptyString()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    $dir = $Path
    while (-not [string]::IsNullOrWhiteSpace($dir)) {
        $gitPath = [System.IO.Path]::Combine($dir, '.git')
        if ([System.IO.Directory]::Exists($gitPath)) {
            return [System.IO.Path]::GetFullPath($gitPath)
        }

        if ([System.IO.File]::Exists($gitPath)) {
            try {
                $line = [System.IO.File]::ReadLines($gitPath) | Select-Object -First 1
                if ($line -match '^gitdir:\s*(.+)$') {
                    $gitDir = $Matches[1].Trim()
                    if (-not [System.IO.Path]::IsPathRooted($gitDir)) {
                        $gitDir = [System.IO.Path]::Combine($dir, $gitDir)
                    }
                    if ([System.IO.Directory]::Exists($gitDir)) {
                        return [System.IO.Path]::GetFullPath($gitDir)
                    }
                }
            } catch {
            }
        }

        $parent = [System.IO.Directory]::GetParent($dir)
        if (-not $parent -or $parent.FullName -eq $dir) {
            break
        }
        $dir = $parent.FullName
    }

    $null
}

function Get-PromptGitBranch {
    param([AllowEmptyString()][string]$Path)

    $gitDir = Get-PromptGitDirectory -Path $Path
    if ([string]::IsNullOrWhiteSpace($gitDir)) {
        return $null
    }

    $headPath = [System.IO.Path]::Combine($gitDir, 'HEAD')
    if (-not [System.IO.File]::Exists($headPath)) {
        return $null
    }

    try {
        $head = ([System.IO.File]::ReadLines($headPath) | Select-Object -First 1).Trim()
    } catch {
        return $null
    }

    if ([string]::IsNullOrWhiteSpace($head)) {
        return $null
    }
    if ($head -match '^ref:\s*refs/heads/(.+)$') {
        return $Matches[1]
    }
    if ($head -match '^ref:\s*(.+)$') {
        return $Matches[1]
    }
    if ($head.Length -gt 7) {
        return $head.Substring(0, 7)
    }

    $head
}

function prompt {
    $success = $?
    $nativeExit = $global:LASTEXITCODE
    $location = Get-Location
    $cwd = if ($location.ProviderPath) { $location.ProviderPath } else { $location.Path }
    $displayCwd = $cwd

    if (-not [string]::IsNullOrWhiteSpace($homeDir) -and
        -not [string]::IsNullOrWhiteSpace($displayCwd) -and
        $displayCwd.StartsWith($homeDir, [System.StringComparison]::OrdinalIgnoreCase)) {
        $displayCwd = '~' + $displayCwd.Substring($homeDir.Length)
    }

    $extra = New-Object 'System.Collections.Generic.List[string]'

    if (-not [string]::IsNullOrWhiteSpace($env:VIRTUAL_ENV)) {
        $extra.Add("$script:AnsiCyan($([System.IO.Path]::GetFileName($env:VIRTUAL_ENV)))$script:AnsiReset")
    } elseif (-not [string]::IsNullOrWhiteSpace($env:CONDA_DEFAULT_ENV) -and $env:CONDA_DEFAULT_ENV -ne 'base') {
        $extra.Add("$script:AnsiCyan($env:CONDA_DEFAULT_ENV)$script:AnsiReset")
    }

    if ($location.Provider.Name -eq 'FileSystem') {
        $branch = Get-PromptGitBranch -Path $cwd
        if (-not [string]::IsNullOrWhiteSpace($branch)) {
            $extra.Add("$script:AnsiMagenta$branch$script:AnsiReset")
        }
    }

    $rc = ''
    if (-not $success) {
        $code = if ($nativeExit -and $nativeExit -ne 0) { $nativeExit } else { 1 }
        $rc = " $script:AnsiRed[$code]$script:AnsiReset"
    }

    $time = Get-Date -Format 'HH:mm:ss'
    $user = [Environment]::UserName
    $extraText = if ($extra.Count -gt 0) { ' ' + ($extra -join ' ') } else { '' }

    "$script:AnsiGray[$time]$script:AnsiReset $script:AnsiGreen$user$script:AnsiWhite@$script:PromptHostName$script:AnsiReset $script:AnsiBlue[$displayCwd]$script:AnsiReset$extraText$rc`n${script:AnsiCyan}PS>$script:AnsiReset "
}

$localAliasesFile = if ([string]::IsNullOrWhiteSpace($env:POWERSHELL_LOCAL_ALIASES_FILE)) {
    [System.IO.Path]::Combine($homeDir, '.aliases')
} else {
    $env:POWERSHELL_LOCAL_ALIASES_FILE
}
Import-LocalAliasFile -Path $localAliasesFile
Remove-Variable localAliasesFile -ErrorAction SilentlyContinue
