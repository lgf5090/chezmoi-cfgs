# Language and toolchain environment variables used by 15-path.ps1.
# Existing values are respected so ~/.envs or parent shells can override.

& {
$homeDir = [Environment]::GetFolderPath('UserProfile')
$xdgDataHome = if ([string]::IsNullOrWhiteSpace($env:XDG_DATA_HOME)) {
    Join-Path $homeDir '.local/share'
} else {
    $env:XDG_DATA_HOME
}

if ([string]::IsNullOrWhiteSpace($env:NPM_CONFIG_PREFIX)) {
    $env:NPM_CONFIG_PREFIX = Join-Path $homeDir '.npm-global'
}
if ([string]::IsNullOrWhiteSpace($env:PNPM_HOME)) {
    $env:PNPM_HOME = Join-Path $homeDir '.pnpm-global'
}
if ([string]::IsNullOrWhiteSpace($env:MISE_DATA_DIR)) {
    $env:MISE_DATA_DIR = Join-Path $xdgDataHome 'mise'
}

if ([string]::IsNullOrWhiteSpace($env:FNM_DIR)) {
    foreach ($candidate in @(
        (Join-Path $xdgDataHome 'fnm'),
        (Join-Path $homeDir '.fnm')
    )) {
        if (-not [System.IO.Directory]::Exists($candidate)) { continue }
        $env:FNM_DIR = [System.IO.Path]::GetFullPath($candidate)
        break
    }
}

if ([string]::IsNullOrWhiteSpace($env:VOLTA_HOME)) {
    $dir = Join-Path $homeDir '.volta'
    if ([System.IO.Directory]::Exists($dir)) { $env:VOLTA_HOME = [System.IO.Path]::GetFullPath($dir) }
}
if ([string]::IsNullOrWhiteSpace($env:BUN_INSTALL)) {
    $dir = Join-Path $homeDir '.bun'
    if ([System.IO.Directory]::Exists($dir)) { $env:BUN_INSTALL = [System.IO.Path]::GetFullPath($dir) }
}
if ([string]::IsNullOrWhiteSpace($env:DENO_INSTALL)) {
    $dir = Join-Path $homeDir '.deno'
    if ([System.IO.Directory]::Exists($dir)) { $env:DENO_INSTALL = [System.IO.Path]::GetFullPath($dir) }
}

if ([string]::IsNullOrWhiteSpace($env:GOPATH)) {
    $env:GOPATH = Join-Path $homeDir 'go'
}
if ([string]::IsNullOrWhiteSpace($env:GOROOT)) {
    foreach ($candidate in @(
        '/home/linuxbrew/.linuxbrew/opt/go/libexec',
        '/opt/homebrew/opt/go/libexec',
        '/usr/local/go',
        (Join-Path $homeDir '.local/go')
    )) {
        if (-not [System.IO.Directory]::Exists($candidate)) { continue }
        $env:GOROOT = [System.IO.Path]::GetFullPath($candidate)
        break
    }
}

if ([string]::IsNullOrWhiteSpace($env:ANACONDA_HOME)) {
    foreach ($candidate in @(
        (Join-Path $homeDir 'anaconda3'),
        (Join-Path $homeDir 'miniconda3'),
        '/opt/anaconda3',
        '/opt/miniconda3'
    )) {
        if (-not [System.IO.Directory]::Exists($candidate)) { continue }
        $env:ANACONDA_HOME = [System.IO.Path]::GetFullPath($candidate)
        break
    }
}

if ([string]::IsNullOrWhiteSpace($env:POETRY_HOME)) {
    $dir = Join-Path $homeDir '.poetry'
    if ([System.IO.Directory]::Exists($dir)) { $env:POETRY_HOME = [System.IO.Path]::GetFullPath($dir) }
}
if ([string]::IsNullOrWhiteSpace($env:PYENV_ROOT)) {
    foreach ($candidate in @(
        (Join-Path $homeDir '.pyenv/pyenv-win'),
        (Join-Path $homeDir '.pyenv')
    )) {
        if (-not [System.IO.Directory]::Exists($candidate)) { continue }
        $env:PYENV_ROOT = [System.IO.Path]::GetFullPath($candidate)
        break
    }
}

if ([string]::IsNullOrWhiteSpace($env:ASDF_DIR)) {
    $asdfCandidates = @((Join-Path $homeDir '.asdf'))
    if (-not [string]::IsNullOrWhiteSpace($env:HOMEBREW_PREFIX)) {
        $asdfCandidates += (Join-Path $env:HOMEBREW_PREFIX 'opt/asdf/libexec')
    }
    $asdfCandidates += @(
        '/home/linuxbrew/.linuxbrew/opt/asdf/libexec',
        '/opt/homebrew/opt/asdf/libexec',
        '/usr/local/opt/asdf/libexec'
    )

    foreach ($candidate in $asdfCandidates) {
        if (-not [System.IO.Directory]::Exists($candidate)) { continue }
        $env:ASDF_DIR = [System.IO.Path]::GetFullPath($candidate)
        break
    }
}

if ([string]::IsNullOrWhiteSpace($env:ASDF_DATA_DIR) -and -not [string]::IsNullOrWhiteSpace($env:ASDF_DIR)) {
    if ((Get-PathComparer).Equals($env:ASDF_DIR, (Join-Path $homeDir '.asdf'))) {
        $env:ASDF_DATA_DIR = $env:ASDF_DIR
    } else {
        $env:ASDF_DATA_DIR = Join-Path $xdgDataHome 'asdf'
    }
}

foreach ($spec in @(
    @('RBENV_ROOT', (Join-Path $homeDir '.rbenv')),
    @('NODENV_ROOT', (Join-Path $homeDir '.nodenv')),
    @('GOENV_ROOT', (Join-Path $homeDir '.goenv')),
    @('JENV_ROOT', (Join-Path $homeDir '.jenv')),
    @('SDKMAN_DIR', (Join-Path $homeDir '.sdkman'))
)) {
    $name = $spec[0]
    if (-not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name, 'Process'))) {
        continue
    }

    $dir = $spec[1]
    if ([System.IO.Directory]::Exists($dir)) {
        [Environment]::SetEnvironmentVariable($name, [System.IO.Path]::GetFullPath($dir), 'Process')
    }
}

if ([string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
    if ([System.IO.File]::Exists('/usr/libexec/java_home')) {
        $javaHome = & /usr/libexec/java_home 2>$null
        if (-not [string]::IsNullOrWhiteSpace($javaHome)) {
            $env:JAVA_HOME = $javaHome
        }
    } else {
        foreach ($candidate in @(
            '/usr/lib/jvm/default-java',
            '/usr/lib/jvm/default',
            '/usr/lib/jvm/java-21-openjdk-amd64',
            '/usr/lib/jvm/java-17-openjdk-amd64',
            '/usr/lib/jvm/java-11-openjdk-amd64'
        )) {
            if (-not [System.IO.Directory]::Exists($candidate)) { continue }
            $env:JAVA_HOME = [System.IO.Path]::GetFullPath($candidate)
            break
        }
    }
}

switch ($global:ShellsOS) {
    { $_ -in @('linux', 'wsl') } {
        foreach ($libDir in @('/usr/lib/x86_64-linux-gnu', '/usr/lib/aarch64-linux-gnu')) {
            if (-not [System.IO.Directory]::Exists($libDir)) { continue }

            $separator = [IO.Path]::PathSeparator
            $separatorPattern = [Regex]::Escape($separator)
            $comparer = Get-PathComparer

            foreach ($name in @('LIBRARY_PATH', 'LD_LIBRARY_PATH')) {
                $current = [Environment]::GetEnvironmentVariable($name, 'Process')
                $contains = $false
                if (-not [string]::IsNullOrWhiteSpace($current)) {
                    foreach ($entry in ($current -split $separatorPattern)) {
                        if ($comparer.Equals($entry, $libDir)) {
                            $contains = $true
                            break
                        }
                    }
                }

                if (-not $contains) {
                    [Environment]::SetEnvironmentVariable(
                        $name,
                        $(if ([string]::IsNullOrWhiteSpace($current)) { $libDir } else { "$libDir$separator$current" }),
                        'Process'
                    )
                }
            }

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

if ([string]::IsNullOrWhiteSpace($env:DOCKER_BUILDKIT)) {
    $env:DOCKER_BUILDKIT = '1'
}
if ([string]::IsNullOrWhiteSpace($env:COMPOSE_DOCKER_CLI_BUILD)) {
    $env:COMPOSE_DOCKER_CLI_BUILD = '1'
}
}
