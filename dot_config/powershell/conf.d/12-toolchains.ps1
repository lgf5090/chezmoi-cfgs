# Language and toolchain environment variables used by 15-path.ps1.
# Existing values are respected so ~/.envs or parent shells can override.

& {
$homeDir = [Environment]::GetFolderPath('UserProfile')
$xdgDataHome = if ([string]::IsNullOrWhiteSpace($env:XDG_DATA_HOME)) {
    Join-Path $homeDir '.local/share'
} else {
    $env:XDG_DATA_HOME
}

function Set-EnvIfMissing {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    if (-not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($Name, 'Process'))) {
        return
    }
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
}

function Get-ExistingDirectoryPath {
    param([Parameter(Mandatory)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }
    if (-not [System.IO.Directory]::Exists($Path)) {
        return $null
    }

    [System.IO.Path]::GetFullPath($Path)
}

function Set-EnvDirIfMissing {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(ValueFromRemainingArguments)][string[]]$Path
    )

    if (-not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($Name, 'Process'))) {
        return
    }

    foreach ($item in $Path) {
        $resolved = Get-ExistingDirectoryPath -Path $item
        if ([string]::IsNullOrWhiteSpace($resolved)) { continue }
        [Environment]::SetEnvironmentVariable($Name, $resolved, 'Process')
        return
    }
}

function Add-EnvPathPrepend {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Path
    )

    $resolved = Get-ExistingDirectoryPath -Path $Path
    if ([string]::IsNullOrWhiteSpace($resolved)) {
        return
    }

    $current = [Environment]::GetEnvironmentVariable($Name, 'Process')
    $separator = [IO.Path]::PathSeparator
    $comparer = Get-PathComparer
    $entries = [System.Collections.Generic.List[string]]::new()
    $entries.Add($resolved)

    if (-not [string]::IsNullOrWhiteSpace($current)) {
        foreach ($entry in ($current -split [Regex]::Escape($separator))) {
            if ([string]::IsNullOrWhiteSpace($entry)) { continue }
            if ($comparer.Equals($entry, $resolved)) { continue }
            $entries.Add($entry)
        }
    }

    [Environment]::SetEnvironmentVariable($Name, ($entries -join $separator), 'Process')
}

Set-EnvIfMissing -Name 'NPM_CONFIG_PREFIX' -Value (Join-Path $homeDir '.npm-global')
Set-EnvIfMissing -Name 'PNPM_HOME' -Value (Join-Path $homeDir '.pnpm-global')
Set-EnvIfMissing -Name 'MISE_DATA_DIR' -Value (Join-Path $xdgDataHome 'mise')

Set-EnvDirIfMissing -Name 'FNM_DIR' `
    (Join-Path $xdgDataHome 'fnm') `
    (Join-Path $homeDir '.fnm')

Set-EnvDirIfMissing -Name 'VOLTA_HOME' (Join-Path $homeDir '.volta')
Set-EnvDirIfMissing -Name 'BUN_INSTALL' (Join-Path $homeDir '.bun')
Set-EnvDirIfMissing -Name 'DENO_INSTALL' (Join-Path $homeDir '.deno')

Set-EnvIfMissing -Name 'GOPATH' -Value (Join-Path $homeDir 'go')
Set-EnvDirIfMissing -Name 'GOROOT' `
    '/home/linuxbrew/.linuxbrew/opt/go/libexec' `
    '/opt/homebrew/opt/go/libexec' `
    '/usr/local/go' `
    (Join-Path $homeDir '.local/go')

Set-EnvDirIfMissing -Name 'ANACONDA_HOME' `
    (Join-Path $homeDir 'anaconda3') `
    (Join-Path $homeDir 'miniconda3') `
    '/opt/anaconda3' `
    '/opt/miniconda3'

Set-EnvDirIfMissing -Name 'POETRY_HOME' (Join-Path $homeDir '.poetry')
Set-EnvDirIfMissing -Name 'PYENV_ROOT' `
    (Join-Path $homeDir '.pyenv/pyenv-win') `
    (Join-Path $homeDir '.pyenv')

$asdfCandidates = @(
    (Join-Path $homeDir '.asdf')
)
if (-not [string]::IsNullOrWhiteSpace($env:HOMEBREW_PREFIX)) {
    $asdfCandidates += (Join-Path $env:HOMEBREW_PREFIX 'opt/asdf/libexec')
}
$asdfCandidates += @(
    '/home/linuxbrew/.linuxbrew/opt/asdf/libexec',
    '/opt/homebrew/opt/asdf/libexec',
    '/usr/local/opt/asdf/libexec'
)
Set-EnvDirIfMissing -Name 'ASDF_DIR' $asdfCandidates

if ([string]::IsNullOrWhiteSpace($env:ASDF_DATA_DIR) -and -not [string]::IsNullOrWhiteSpace($env:ASDF_DIR)) {
    if ((Get-PathComparer).Equals($env:ASDF_DIR, (Join-Path $homeDir '.asdf'))) {
        $env:ASDF_DATA_DIR = $env:ASDF_DIR
    } else {
        $env:ASDF_DATA_DIR = Join-Path $xdgDataHome 'asdf'
    }
}

Set-EnvDirIfMissing -Name 'RBENV_ROOT' (Join-Path $homeDir '.rbenv')
Set-EnvDirIfMissing -Name 'NODENV_ROOT' (Join-Path $homeDir '.nodenv')
Set-EnvDirIfMissing -Name 'GOENV_ROOT' (Join-Path $homeDir '.goenv')
Set-EnvDirIfMissing -Name 'JENV_ROOT' (Join-Path $homeDir '.jenv')
Set-EnvDirIfMissing -Name 'SDKMAN_DIR' (Join-Path $homeDir '.sdkman')

if ([string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
    if ([System.IO.File]::Exists('/usr/libexec/java_home')) {
        $javaHome = & /usr/libexec/java_home 2>$null
        if (-not [string]::IsNullOrWhiteSpace($javaHome)) {
            $env:JAVA_HOME = $javaHome
        }
    } else {
        Set-EnvDirIfMissing -Name 'JAVA_HOME' `
            '/usr/lib/jvm/default-java' `
            '/usr/lib/jvm/default' `
            '/usr/lib/jvm/java-21-openjdk-amd64' `
            '/usr/lib/jvm/java-17-openjdk-amd64' `
            '/usr/lib/jvm/java-11-openjdk-amd64'
    }
}

switch ($global:ShellsOS) {
    { $_ -in @('linux', 'wsl') } {
        foreach ($libDir in @('/usr/lib/x86_64-linux-gnu', '/usr/lib/aarch64-linux-gnu')) {
            if (-not (Test-Path -LiteralPath $libDir -PathType Container)) { continue }

            Add-EnvPathPrepend -Name 'LIBRARY_PATH' -Path $libDir
            Add-EnvPathPrepend -Name 'LD_LIBRARY_PATH' -Path $libDir

            if (" $env:RUSTFLAGS " -notlike "* -L $libDir *") {
                $env:RUSTFLAGS = if ([string]::IsNullOrWhiteSpace($env:RUSTFLAGS)) {
                    "-L $libDir"
                } else {
                    "-L $libDir $env:RUSTFLAGS"
                }
            }
            break
        }
    }
}

Set-EnvIfMissing -Name 'DOCKER_BUILDKIT' -Value '1'
Set-EnvIfMissing -Name 'COMPOSE_DOCKER_CLI_BUILD' -Value '1'
}
