$script:SpmUnixManagers = @(
    'brew',
    'apt', 'apt-get', 'nala',
    'dnf', 'dnf5', 'yum', 'microdnf',
    'apk', 'pacman', 'paru', 'yay', 'zypper',
    'xbps-install', 'emerge', 'eopkg', 'swupd',
    'pkg', 'pkg_add', 'pkgin', 'port',
    'nix-env', 'profile', 'nix', 'guix', 'conda'
)
$script:SpmWindowsManagers = @('winget', 'scoop', 'choco')
$script:SpmSudoManagers = @(
    'apt', 'apt-get', 'nala', 'dnf', 'dnf5', 'yum', 'microdnf', 'apk',
    'pacman', 'zypper', 'xbps-install', 'emerge', 'eopkg', 'swupd',
    'pkg', 'pkg_add', 'port'
)

function Show-SpmHelp {
    @'
spm - simple cross-platform package manager helper

USAGE
  spm [package ...]
  spm -i | --install package ...
  spm -u | --upgrade [package ...]
  spm -s | --search query
  spm -r | --remove package ...
  spm --info package
  spm --list [query]
  spm --update
  spm --clean
  spm --manager NAME action [package ...]
  spm --dry-run action [package ...]
  spm -h | --help

DEFAULTS
  spm git
      Install git. On Debian/Ubuntu this runs: sudo apt install -y git

  spm -i git
  spm --install git
      Install git.

  spm -u git
  spm --upgrade git
      Upgrade git.

  spm -u
  spm --upgrade
      Upgrade all packages. On Debian/Ubuntu this runs:
        sudo apt update && sudo apt upgrade -y

  spm -s git
  spm --search git
      Search package names/descriptions.

MORE EXAMPLES
  spm --remove git
  spm --info git
  spm --list git
  spm --update
  spm --clean
  spm --which
  spm --dry-run -u
  spm -m apt install curl
  spm --manager brew search ripgrep

PACKAGE MANAGER PRIORITY
  Unix, Linux, macOS, WSL, WSL2:
    brew first, then system managers such as apt, dnf, yum, apk, pacman,
    zypper, xbps-install, emerge, eopkg, swupd, pkg, pkg_add, pkgin,
    port, nix, guix, and conda.

  Windows shells:
    winget, then scoop, then choco.

OPTIONS
  -i, --install       install packages
  -u, --upgrade       upgrade packages, or all packages when no package is given
  -s, --search        search packages
  -r, --remove        remove packages
      --info          show package details
  -l, --list          list installed packages, optionally filtered by query
      --update        refresh package indexes
      --clean         clean package manager caches when supported
      --which         print selected package manager
  -m, --manager NAME  force a package manager for this invocation
      --dry-run       print commands without running them
  -h, --help          show this help

ENVIRONMENT
  SPM_MANAGER         default package manager override, same as --manager
  SPM_NO_SUDO=1       never prepend sudo
'@
}

function Test-SpmCommand {
    param([Parameter(Mandatory)][string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-SpmWindows {
    [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows
    )
}

function Get-SpmManager {
    if (-not [string]::IsNullOrWhiteSpace($env:SPM_MANAGER)) {
        return $env:SPM_MANAGER
    }

    $managers = if (Test-SpmWindows) { $script:SpmWindowsManagers } else { $script:SpmUnixManagers }
    foreach ($manager in $managers) {
        if ($manager -eq 'profile') {
            if (Test-SpmCommand nix) {
                & nix profile --help *> $null
                if ($LASTEXITCODE -eq 0) { return 'nix-profile' }
            }
            continue
        }

        if (Test-SpmCommand $manager) {
            return $manager
        }
    }

    throw 'spm: no supported package manager found'
}

function Test-SpmNeedsSudo {
    param([Parameter(Mandatory)][string]$Manager)

    if ($env:SPM_NO_SUDO -eq '1') { return $false }
    if (-not ($script:SpmSudoManagers -contains $Manager)) { return $false }
    if (-not (Test-SpmCommand sudo)) { return $false }

    try {
        $uid = (& id -u 2>$null).Trim()
        if ($uid -eq '0') { return $false }
    } catch {
        return $false
    }

    $true
}

function New-SpmCommand {
    param(
        [Parameter(Mandatory)][bool]$UseSudo,
        [Parameter(Mandatory)][string[]]$Argv
    )
    [pscustomobject]@{
        UseSudo = $UseSudo
        Argv = $Argv
    }
}

function Join-SpmWords {
    param([string[]]$Items)
    $Items -join ' '
}

function Require-SpmPackages {
    param(
        [Parameter(Mandatory)][string]$Action,
        [string[]]$Packages
    )
    if (-not $Packages -or $Packages.Count -eq 0) {
        throw "spm: $Action requires at least one package/query"
    }
}

function New-SpmUnsupportedError {
    param(
        [Parameter(Mandatory)][string]$Manager,
        [Parameter(Mandatory)][string]$Action
    )
    throw "spm: $Manager does not support action: $Action"
}

function Get-SpmCommands {
    param(
        [Parameter(Mandatory)][string]$Manager,
        [Parameter(Mandatory)][string]$Action,
        [string[]]$Packages = @()
    )

    switch ($Manager) {
        { $_ -in @('apt', 'apt-get') } {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@($Manager, 'install', '-y') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) {
                        return @(
                            (New-SpmCommand $true @($Manager, 'update')),
                            (New-SpmCommand $true @($Manager, 'upgrade', '-y'))
                        )
                    }
                    return @(New-SpmCommand $true (@($Manager, 'install', '--only-upgrade', '-y') + $Packages))
                }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@($Manager, 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@($Manager, 'remove', '-y') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@($Manager, 'show') + $Packages)) }
                list { return @(New-SpmCommand $false (@($Manager, 'list', '--installed') + $Packages)) }
                update { return @(New-SpmCommand $true @($Manager, 'update')) }
                clean {
                    return @(
                        (New-SpmCommand $true @($Manager, 'autoremove', '-y')),
                        (New-SpmCommand $true @($Manager, 'autoclean'))
                    )
                }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        nala {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('nala', 'install', '-y') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) {
                        return @(
                            (New-SpmCommand $true @('nala', 'update')),
                            (New-SpmCommand $true @('nala', 'upgrade', '-y'))
                        )
                    }
                    return @(New-SpmCommand $true (@('nala', 'install', '--only-upgrade', '-y') + $Packages))
                }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('nala', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('nala', 'remove', '-y') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('nala', 'show') + $Packages)) }
                list { return @(New-SpmCommand $false (@('apt', 'list', '--installed') + $Packages)) }
                update { return @(New-SpmCommand $true @('nala', 'update')) }
                clean {
                    return @(
                        (New-SpmCommand $true @('apt', 'autoremove', '-y')),
                        (New-SpmCommand $true @('apt', 'autoclean'))
                    )
                }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        brew {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('brew', 'install') + $Packages)) }
                upgrade { return @(New-SpmCommand $false (@('brew', 'upgrade') + $Packages)) }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('brew', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('brew', 'uninstall') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('brew', 'info') + $Packages)) }
                list { return @(New-SpmCommand $false (@('brew', 'list') + $Packages)) }
                update { return @(New-SpmCommand $false @('brew', 'update')) }
                clean { return @(New-SpmCommand $false @('brew', 'cleanup')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        { $_ -in @('dnf', 'dnf5', 'yum', 'microdnf') } {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@($Manager, 'install', '-y') + $Packages)) }
                upgrade { return @(New-SpmCommand $true (@($Manager, 'upgrade', '-y') + $Packages)) }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@($Manager, 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@($Manager, 'remove', '-y') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@($Manager, 'info') + $Packages)) }
                list { return @(New-SpmCommand $false (@($Manager, 'list', 'installed') + $Packages)) }
                update { return @(New-SpmCommand $true @($Manager, 'makecache')) }
                clean { return @(New-SpmCommand $true @($Manager, 'clean', 'all')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        apk {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('apk', 'add') + $Packages)) }
                upgrade { return @(New-SpmCommand $true (@('apk', 'upgrade') + $Packages)) }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('apk', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('apk', 'del') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('apk', 'info') + $Packages)) }
                list { return @(New-SpmCommand $false (@('apk', 'info') + $Packages)) }
                update { return @(New-SpmCommand $true @('apk', 'update')) }
                clean { return @(New-SpmCommand $true @('apk', 'cache', 'clean')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        pacman {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('pacman', '-S', '--needed', '--noconfirm') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) { return @(New-SpmCommand $true @('pacman', '-Syu', '--noconfirm')) }
                    return @(New-SpmCommand $true (@('pacman', '-S', '--needed', '--noconfirm') + $Packages))
                }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('pacman', '-Ss') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('pacman', '-Rns', '--noconfirm') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('pacman', '-Si') + $Packages)) }
                list { return @(New-SpmCommand $false (@('pacman', '-Qs') + $Packages)) }
                update { return @(New-SpmCommand $true @('pacman', '-Sy')) }
                clean { return @(New-SpmCommand $true @('pacman', '-Sc', '--noconfirm')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        { $_ -in @('paru', 'yay') } {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@($Manager, '-S', '--needed', '--noconfirm') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) { return @(New-SpmCommand $false @($Manager, '-Syu', '--noconfirm')) }
                    return @(New-SpmCommand $false (@($Manager, '-S', '--needed', '--noconfirm') + $Packages))
                }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@($Manager, '-Ss') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@($Manager, '-Rns', '--noconfirm') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@($Manager, '-Si') + $Packages)) }
                list { return @(New-SpmCommand $false (@($Manager, '-Qs') + $Packages)) }
                update { return @(New-SpmCommand $false @($Manager, '-Sy')) }
                clean { return @(New-SpmCommand $false @($Manager, '-Sc', '--noconfirm')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        zypper {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('zypper', '--non-interactive', 'install') + $Packages)) }
                upgrade { return @(New-SpmCommand $true (@('zypper', '--non-interactive', 'update') + $Packages)) }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('zypper', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('zypper', '--non-interactive', 'remove') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('zypper', 'info') + $Packages)) }
                list { return @(New-SpmCommand $false (@('zypper', 'search', '--installed-only') + $Packages)) }
                update { return @(New-SpmCommand $true @('zypper', 'refresh')) }
                clean { return @(New-SpmCommand $true @('zypper', 'clean', '--all')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        'xbps-install' {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('xbps-install', '-Sy') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) { return @(New-SpmCommand $true @('xbps-install', '-Syu')) }
                    return @(New-SpmCommand $true (@('xbps-install', '-Su') + $Packages))
                }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false @('xbps-query', '-Rs', (Join-SpmWords $Packages))) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('xbps-remove', '-R') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('xbps-query', '-RS') + $Packages)) }
                list { return @(New-SpmCommand $false (@('xbps-query', '-l') + $Packages)) }
                update { return @(New-SpmCommand $true @('xbps-install', '-S')) }
                clean { return @(New-SpmCommand $true @('xbps-remove', '-O')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        emerge {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('emerge', '--ask=n') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) { return @(New-SpmCommand $true @('emerge', '--ask=n', '--update', '--deep', '--newuse', '@world')) }
                    return @(New-SpmCommand $true (@('emerge', '--ask=n', '--update') + $Packages))
                }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false @('emerge', '--search', (Join-SpmWords $Packages))) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('emerge', '--ask=n', '--depclean') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('equery', 'meta') + $Packages)) }
                list { return @(New-SpmCommand $false (@('equery', 'list') + $Packages)) }
                update { return @(New-SpmCommand $true @('emerge', '--sync')) }
                clean { return @(New-SpmCommand $true @('emerge', '--ask=n', '--depclean')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        eopkg {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('eopkg', 'install', '-y') + $Packages)) }
                upgrade { return @(New-SpmCommand $true (@('eopkg', 'upgrade', '-y') + $Packages)) }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('eopkg', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('eopkg', 'remove', '-y') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('eopkg', 'info') + $Packages)) }
                list { return @(New-SpmCommand $false (@('eopkg', 'list-installed') + $Packages)) }
                update { return @(New-SpmCommand $true @('eopkg', 'update-repo')) }
                clean { return @(New-SpmCommand $true @('eopkg', 'clean')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        swupd {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('swupd', 'bundle-add') + $Packages)) }
                upgrade { return @(New-SpmCommand $true (@('swupd', 'update') + $Packages)) }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('swupd', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('swupd', 'bundle-remove') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('swupd', 'bundle-info') + $Packages)) }
                list { return @(New-SpmCommand $false (@('swupd', 'bundle-list') + $Packages)) }
                update { return @(New-SpmCommand $true @('swupd', 'update', '--download')) }
                clean { return @(New-SpmCommand $true @('swupd', 'clean')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        pkg {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('pkg', 'install', '-y') + $Packages)) }
                upgrade { return @(New-SpmCommand $true (@('pkg', 'upgrade', '-y') + $Packages)) }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('pkg', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('pkg', 'delete', '-y') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('pkg', 'info') + $Packages)) }
                list { return @(New-SpmCommand $false (@('pkg', 'info') + $Packages)) }
                update { return @(New-SpmCommand $true @('pkg', 'update')) }
                clean { return @(New-SpmCommand $true @('pkg', 'clean', '-y')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        pkg_add {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('pkg_add') + $Packages)) }
                upgrade { return @(New-SpmCommand $true (@('pkg_add', '-u') + $Packages)) }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false @('pkg_info', '-Q', (Join-SpmWords $Packages))) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('pkg_delete') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('pkg_info') + $Packages)) }
                list { return @(New-SpmCommand $false (@('pkg_info') + $Packages)) }
                update { return @(New-SpmCommand $true @('pkg_add', '-u')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        pkgin {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('pkgin', '-y', 'install') + $Packages)) }
                upgrade { return @(New-SpmCommand $true (@('pkgin', '-y', 'upgrade') + $Packages)) }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('pkgin', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('pkgin', '-y', 'remove') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('pkgin', 'show-full-deps') + $Packages)) }
                list { return @(New-SpmCommand $false (@('pkgin', 'list') + $Packages)) }
                update { return @(New-SpmCommand $true @('pkgin', 'update')) }
                clean { return @(New-SpmCommand $true @('pkgin', 'clean')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        port {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('port', 'install') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) {
                        return @(
                            (New-SpmCommand $true @('port', 'selfupdate')),
                            (New-SpmCommand $true @('port', 'upgrade', 'outdated'))
                        )
                    }
                    return @(New-SpmCommand $true (@('port', 'upgrade') + $Packages))
                }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('port', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $true (@('port', 'uninstall') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('port', 'info') + $Packages)) }
                list { return @(New-SpmCommand $false (@('port', 'installed') + $Packages)) }
                update { return @(New-SpmCommand $true @('port', 'selfupdate')) }
                clean { return @(New-SpmCommand $true @('port', 'clean', '--all', 'all')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        winget {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('winget', 'install', '--accept-package-agreements', '--accept-source-agreements') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) { return @(New-SpmCommand $false @('winget', 'upgrade', '--all', '--accept-package-agreements', '--accept-source-agreements')) }
                    return @(New-SpmCommand $false (@('winget', 'upgrade', '--accept-package-agreements', '--accept-source-agreements') + $Packages))
                }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('winget', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('winget', 'uninstall') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('winget', 'show') + $Packages)) }
                list { return @(New-SpmCommand $false (@('winget', 'list') + $Packages)) }
                update { return @(New-SpmCommand $false @('winget', 'source', 'update')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        scoop {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('scoop', 'install') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) {
                        return @(
                            (New-SpmCommand $false @('scoop', 'update')),
                            (New-SpmCommand $false @('scoop', 'update', '*'))
                        )
                    }
                    return @(New-SpmCommand $false (@('scoop', 'update') + $Packages))
                }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('scoop', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('scoop', 'uninstall') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('scoop', 'info') + $Packages)) }
                list { return @(New-SpmCommand $false (@('scoop', 'list') + $Packages)) }
                update { return @(New-SpmCommand $false @('scoop', 'update')) }
                clean { return @(New-SpmCommand $false @('scoop', 'cleanup', '*')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        choco {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('choco', 'install', '-y') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) { return @(New-SpmCommand $false @('choco', 'upgrade', 'all', '-y')) }
                    return @(New-SpmCommand $false (@('choco', 'upgrade', '-y') + $Packages))
                }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('choco', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('choco', 'uninstall', '-y') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('choco', 'info') + $Packages)) }
                list { return @(New-SpmCommand $false (@('choco', 'list', '--local-only') + $Packages)) }
                update { return @(New-SpmCommand $false @('choco', 'outdated')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        'nix-env' {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('nix-env', '-iA') + $Packages)) }
                upgrade { return @(New-SpmCommand $false (@('nix-env', '-u') + $Packages)) }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('nix-env', '-qaP') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('nix-env', '-e') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('nix-env', '-qa', '--description') + $Packages)) }
                list { return @(New-SpmCommand $false (@('nix-env', '-q') + $Packages)) }
                update { return @(New-SpmCommand $false @('nix-channel', '--update')) }
                clean { return @(New-SpmCommand $false @('nix-collect-garbage', '-d')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        'nix-profile' {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('nix', 'profile', 'install') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) { return @(New-SpmCommand $false @('nix', 'profile', 'upgrade', '--all')) }
                    return @(New-SpmCommand $false (@('nix', 'profile', 'upgrade') + $Packages))
                }
                { $_ -in @('search', 'info') } { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false @('nix', 'search', 'nixpkgs', (Join-SpmWords $Packages))) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('nix', 'profile', 'remove') + $Packages)) }
                list { return @(New-SpmCommand $false (@('nix', 'profile', 'list') + $Packages)) }
                clean { return @(New-SpmCommand $false @('nix', 'store', 'gc')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        nix {
            switch ($Action) {
                { $_ -in @('search', 'info') } { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false @('nix', 'search', 'nixpkgs', (Join-SpmWords $Packages))) }
                list { return @(New-SpmCommand $false (@('nix', 'profile', 'list') + $Packages)) }
                clean { return @(New-SpmCommand $false @('nix', 'store', 'gc')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        guix {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('guix', 'install') + $Packages)) }
                upgrade { return @(New-SpmCommand $false (@('guix', 'upgrade') + $Packages)) }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('guix', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('guix', 'remove') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('guix', 'show') + $Packages)) }
                list { return @(New-SpmCommand $false (@('guix', 'package', '--list-installed') + $Packages)) }
                update { return @(New-SpmCommand $false @('guix', 'pull')) }
                clean { return @(New-SpmCommand $false @('guix', 'gc')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        conda {
            switch ($Action) {
                install { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('conda', 'install', '-y') + $Packages)) }
                upgrade {
                    if ($Packages.Count -eq 0) { return @(New-SpmCommand $false @('conda', 'update', '-y', '--all')) }
                    return @(New-SpmCommand $false (@('conda', 'update', '-y') + $Packages))
                }
                search { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('conda', 'search') + $Packages)) }
                remove { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('conda', 'remove', '-y') + $Packages)) }
                info { Require-SpmPackages $Action $Packages; return @(New-SpmCommand $false (@('conda', 'search', '--info') + $Packages)) }
                list { return @(New-SpmCommand $false (@('conda', 'list') + $Packages)) }
                update { return @(New-SpmCommand $false @('conda', 'update', '-y', 'conda')) }
                clean { return @(New-SpmCommand $false @('conda', 'clean', '-a', '-y')) }
                default { New-SpmUnsupportedError $Manager $Action }
            }
        }
        default {
            throw "spm: unsupported package manager: $Manager"
        }
    }
}

function Format-SpmArgument {
    param([Parameter(Mandatory)][string]$Value)
    if ($Value -match '^[A-Za-z0-9_./:@%+=,-]+$') {
        return $Value
    }
    "'$($Value.Replace("'", "''"))'"
}

function Invoke-SpmCommands {
    param(
        [Parameter(Mandatory)][string]$Manager,
        [Parameter(Mandatory)]$Commands,
        [switch]$DryRun
    )

    foreach ($command in $Commands) {
        $argv = @($command.Argv)
        if ($command.UseSudo -and (Test-SpmNeedsSudo $Manager)) {
            $argv = @('sudo') + $argv
        }

        if ($DryRun) {
            "+ $(($argv | ForEach-Object { Format-SpmArgument $_ }) -join ' ')"
            continue
        }

        $bin = $argv[0]
        $cmdArgs = @()
        if ($argv.Count -gt 1) {
            $cmdArgs = $argv[1..($argv.Count - 1)]
        }
        & $bin @cmdArgs
        if ($LASTEXITCODE -ne 0) {
            throw "spm: command failed with exit code $LASTEXITCODE"
        }
    }
}

function Get-SpmActionAlias {
    param([Parameter(Mandatory)][string]$Value)
    switch ($Value) {
        { $_ -in @('install', 'add') } { 'install'; break }
        { $_ -in @('upgrade', 'update-all') } { 'upgrade'; break }
        search { 'search'; break }
        { $_ -in @('remove', 'rm', 'uninstall') } { 'remove'; break }
        { $_ -in @('info', 'show') } { 'info'; break }
        { $_ -in @('list', 'ls') } { 'list'; break }
        refresh { 'update'; break }
        clean { 'clean'; break }
        default { '' }
    }
}

function spm {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Args
    )

    $action = 'install'
    $actionExplicit = $false
    $manager = if ([string]::IsNullOrWhiteSpace($env:SPM_MANAGER)) { '' } else { $env:SPM_MANAGER }
    $dryRun = $false
    $which = $false
    $index = 0

    :parse while ($index -lt $Args.Count) {
        $arg = $Args[$index]
        switch ($arg) {
            { $_ -in @('-h', '--help') } {
                Show-SpmHelp
                return
            }
            '--which' {
                $which = $true
                $index += 1
                continue
            }
            '--dry-run' {
                $dryRun = $true
                $index += 1
                continue
            }
            { $_ -in @('-m', '--manager') } {
                if (($index + 1) -ge $Args.Count) {
                    Write-Error "spm: $arg requires a package manager name"
                    return 2
                }
                $manager = $Args[$index + 1]
                $index += 2
                continue
            }
            { $_ -like '--manager=*' } {
                $manager = $arg.Substring('--manager='.Length)
                $index += 1
                continue
            }
            { $_ -in @('-i', '--install', 'install', 'add') } {
                $action = 'install'
                $actionExplicit = $true
                $index += 1
                continue
            }
            { $_ -in @('-u', '--upgrade', 'upgrade', 'update-all') } {
                $action = 'upgrade'
                $actionExplicit = $true
                $index += 1
                continue
            }
            { $_ -in @('-s', '--search', 'search') } {
                $action = 'search'
                $actionExplicit = $true
                $index += 1
                continue
            }
            { $_ -in @('-r', '--remove', 'remove', 'rm', 'uninstall') } {
                $action = 'remove'
                $actionExplicit = $true
                $index += 1
                continue
            }
            { $_ -in @('--info', 'info', 'show') } {
                $action = 'info'
                $actionExplicit = $true
                $index += 1
                continue
            }
            { $_ -in @('-l', '--list', 'list', 'ls') } {
                $action = 'list'
                $actionExplicit = $true
                $index += 1
                continue
            }
            { $_ -in @('--update', 'refresh') } {
                $action = 'update'
                $actionExplicit = $true
                $index += 1
                continue
            }
            { $_ -in @('--clean', 'clean') } {
                $action = 'clean'
                $actionExplicit = $true
                $index += 1
                continue
            }
            '--' {
                $index += 1
                break parse
            }
            '--%' {
                $index += 1
                continue
            }
            { $_.StartsWith('-') } {
                Write-Error "spm: unknown option: $arg"
                Write-Error 'Run `spm --help` for usage.'
                return 2
            }
            default {
                break parse
            }
        }
    }

    $packages = @()
    if ($index -lt $Args.Count) {
        $packages = @($Args[$index..($Args.Count - 1)])
    }

    if (-not $actionExplicit -and $packages.Count -gt 0) {
        $alias = Get-SpmActionAlias $packages[0]
        if (-not [string]::IsNullOrWhiteSpace($alias)) {
            $action = $alias
            if ($packages.Count -gt 1) {
                $packages = @($packages[1..($packages.Count - 1)])
            } else {
                $packages = @()
            }
        }
    }

    try {
        if ([string]::IsNullOrWhiteSpace($manager)) {
            $manager = Get-SpmManager
        }

        if ($which) {
            $manager
            return
        }

        $commands = Get-SpmCommands -Manager $manager -Action $action -Packages $packages
        Invoke-SpmCommands -Manager $manager -Commands $commands -DryRun:$dryRun
    } catch {
        Write-Error $_.Exception.Message
        return 1
    }
}
