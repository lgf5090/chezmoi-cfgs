const spm_unix_managers = [
    brew
    apt apt-get nala
    dnf dnf5 yum microdnf
    apk pacman paru yay zypper
    xbps-install emerge eopkg swupd
    pkg pkg_add pkgin port
    nix-env profile nix guix conda
]

const spm_windows_managers = [winget scoop choco]

const spm_sudo_managers = [
    apt apt-get nala dnf dnf5 yum microdnf apk pacman zypper
    xbps-install emerge eopkg swupd pkg pkg_add port
]

def _spm-usage [] {
    [
        'spm - simple cross-platform package manager helper'
        ''
        'USAGE'
        '  spm [package ...]'
        '  spm -i | --install package ...'
        '  spm -u | --upgrade [package ...]'
        '  spm -s | --search query'
        '  spm -r | --remove package ...'
        '  spm --info package'
        '  spm --list [query]'
        '  spm --update'
        '  spm --clean'
        '  spm --manager NAME action [package ...]'
        '  spm --dry-run action [package ...]'
        '  spm -h | --help'
        ''
        'DEFAULTS'
        '  spm git'
        '      Install git. On Debian/Ubuntu this runs: sudo apt install -y git'
        ''
        '  spm -i git'
        '  spm --install git'
        '      Install git.'
        ''
        '  spm -u git'
        '  spm --upgrade git'
        '      Upgrade git.'
        ''
        '  spm -u'
        '  spm --upgrade'
        '      Upgrade all packages. On Debian/Ubuntu this runs:'
        '        sudo apt update && sudo apt upgrade -y'
        ''
        '  spm -s git'
        '  spm --search git'
        '      Search package names/descriptions.'
        ''
        'MORE EXAMPLES'
        '  spm --remove git'
        '  spm --info git'
        '  spm --list git'
        '  spm --update'
        '  spm --clean'
        '  spm --which'
        '  spm --dry-run -u'
        '  spm -m apt install curl'
        '  spm --manager brew search ripgrep'
        ''
        'PACKAGE MANAGER PRIORITY'
        '  Unix, Linux, macOS, WSL, WSL2:'
        '    brew first, then system managers such as apt, dnf, yum, apk, pacman,'
        '    zypper, xbps-install, emerge, eopkg, swupd, pkg, pkg_add, pkgin,'
        '    port, nix, guix, and conda.'
        ''
        '  Windows shells:'
        '    winget, then scoop, then choco.'
        ''
        'OPTIONS'
        '  -i, --install       install packages'
        '  -u, --upgrade       upgrade packages, or all packages when no package is given'
        '  -s, --search        search packages'
        '  -r, --remove        remove packages'
        '      --info          show package details'
        '  -l, --list          list installed packages, optionally filtered by query'
        '      --update        refresh package indexes'
        '      --clean         clean package manager caches when supported'
        '      --which         print selected package manager'
        '  -m, --manager NAME  force a package manager for this invocation'
        '      --dry-run       print commands without running them'
        '  -h, --help          show this help'
        ''
        'ENVIRONMENT'
        '  SPM_MANAGER         default package manager override, same as --manager'
        '  SPM_NO_SUDO=1       never prepend sudo'
    ] | str join (char nl) | print
}

def _spm-command-exists [name: string] {
    which $name | is-not-empty
}

def _spm-is-windows [] {
    ($nu.os-info.family? | default '') == 'windows'
}

def _spm-detect-manager [] {
    if (($env.SPM_MANAGER? | default '') | is-not-empty) {
        return $env.SPM_MANAGER
    }

    let managers = if (_spm-is-windows) { $spm_windows_managers } else { $spm_unix_managers }
    for manager in $managers {
        match $manager {
            profile => {
                if (_spm-command-exists nix) {
                    let result = (^nix profile --help o+e>| complete)
                    if $result.exit_code == 0 {
                        return nix-profile
                    }
                }
            }
            _ => {
                if (_spm-command-exists $manager) {
                    return $manager
                }
            }
        }
    }

    error make {msg: 'spm: no supported package manager found'}
}

def _spm-require-packages [action: string, packages: list<string>] {
    if ($packages | is-empty) {
        error make {msg: $'spm: ($action) requires at least one package/query'}
    }
}

def _spm-unsupported [manager: string, action: string] {
    error make {msg: $'spm: ($manager) does not support action: ($action)'}
}

def _spm-cmd [sudo: bool, argv: list<string>] {
    {sudo: $sudo, argv: $argv}
}

def _spm-join [items: list<string>] {
    $items | str join ' '
}

def _spm-build-commands [
    manager: string
    action: string
    packages: list<string>
] {
    match $manager {
        apt | apt-get => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([$manager install -y] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [
                            (_spm-cmd true [$manager update])
                            (_spm-cmd true [$manager upgrade -y])
                        ]
                    } else {
                        [(_spm-cmd true ([$manager install --only-upgrade -y] ++ $packages))]
                    }
                }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([$manager search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([$manager remove -y] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([$manager show] ++ $packages))]
                }
                list => { [(_spm-cmd false ([$manager list --installed] ++ $packages))] }
                update => { [(_spm-cmd true [$manager update])] }
                clean => {
                    [
                        (_spm-cmd true [$manager autoremove -y])
                        (_spm-cmd true [$manager autoclean])
                    ]
                }
                _ => { _spm-unsupported $manager $action }
            }
        }
        nala => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([nala install -y] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [
                            (_spm-cmd true [nala update])
                            (_spm-cmd true [nala upgrade -y])
                        ]
                    } else {
                        [(_spm-cmd true ([nala install --only-upgrade -y] ++ $packages))]
                    }
                }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([nala search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([nala remove -y] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([nala show] ++ $packages))]
                }
                list => { [(_spm-cmd false ([apt list --installed] ++ $packages))] }
                update => { [(_spm-cmd true [nala update])] }
                clean => {
                    [
                        (_spm-cmd true [apt autoremove -y])
                        (_spm-cmd true [apt autoclean])
                    ]
                }
                _ => { _spm-unsupported $manager $action }
            }
        }
        brew => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([brew install] ++ $packages))]
                }
                upgrade => { [(_spm-cmd false ([brew upgrade] ++ $packages))] }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([brew search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([brew uninstall] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([brew info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([brew list] ++ $packages))] }
                update => { [(_spm-cmd false [brew update])] }
                clean => { [(_spm-cmd false [brew cleanup])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        dnf | dnf5 | yum | microdnf => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([$manager install -y] ++ $packages))]
                }
                upgrade => { [(_spm-cmd true ([$manager upgrade -y] ++ $packages))] }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([$manager search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([$manager remove -y] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([$manager info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([$manager list installed] ++ $packages))] }
                update => { [(_spm-cmd true [$manager makecache])] }
                clean => { [(_spm-cmd true [$manager clean all])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        apk => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([apk add] ++ $packages))]
                }
                upgrade => { [(_spm-cmd true ([apk upgrade] ++ $packages))] }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([apk search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([apk del] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([apk info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([apk info] ++ $packages))] }
                update => { [(_spm-cmd true [apk update])] }
                clean => { [(_spm-cmd true [apk cache clean])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        pacman => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([pacman -S --needed --noconfirm] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [(_spm-cmd true [pacman -Syu --noconfirm])]
                    } else {
                        [(_spm-cmd true ([pacman -S --needed --noconfirm] ++ $packages))]
                    }
                }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([pacman -Ss] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([pacman -Rns --noconfirm] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([pacman -Si] ++ $packages))]
                }
                list => { [(_spm-cmd false ([pacman -Qs] ++ $packages))] }
                update => { [(_spm-cmd true [pacman -Sy])] }
                clean => { [(_spm-cmd true [pacman -Sc --noconfirm])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        paru | yay => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([$manager -S --needed --noconfirm] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [(_spm-cmd false [$manager -Syu --noconfirm])]
                    } else {
                        [(_spm-cmd false ([$manager -S --needed --noconfirm] ++ $packages))]
                    }
                }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([$manager -Ss] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([$manager -Rns --noconfirm] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([$manager -Si] ++ $packages))]
                }
                list => { [(_spm-cmd false ([$manager -Qs] ++ $packages))] }
                update => { [(_spm-cmd false [$manager -Sy])] }
                clean => { [(_spm-cmd false [$manager -Sc --noconfirm])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        zypper => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([zypper --non-interactive install] ++ $packages))]
                }
                upgrade => { [(_spm-cmd true ([zypper --non-interactive update] ++ $packages))] }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([zypper search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([zypper --non-interactive remove] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([zypper info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([zypper search --installed-only] ++ $packages))] }
                update => { [(_spm-cmd true [zypper refresh])] }
                clean => { [(_spm-cmd true [zypper clean --all])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        xbps-install => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([xbps-install -Sy] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [(_spm-cmd true [xbps-install -Syu])]
                    } else {
                        [(_spm-cmd true ([xbps-install -Su] ++ $packages))]
                    }
                }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false [xbps-query -Rs (_spm-join $packages)])]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([xbps-remove -R] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([xbps-query -RS] ++ $packages))]
                }
                list => { [(_spm-cmd false ([xbps-query -l] ++ $packages))] }
                update => { [(_spm-cmd true [xbps-install -S])] }
                clean => { [(_spm-cmd true [xbps-remove -O])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        emerge => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([emerge --ask=n] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [(_spm-cmd true [emerge --ask=n --update --deep --newuse @world])]
                    } else {
                        [(_spm-cmd true ([emerge --ask=n --update] ++ $packages))]
                    }
                }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false [emerge --search (_spm-join $packages)])]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([emerge --ask=n --depclean] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([equery meta] ++ $packages))]
                }
                list => { [(_spm-cmd false ([equery list] ++ $packages))] }
                update => { [(_spm-cmd true [emerge --sync])] }
                clean => { [(_spm-cmd true [emerge --ask=n --depclean])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        eopkg => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([eopkg install -y] ++ $packages))]
                }
                upgrade => { [(_spm-cmd true ([eopkg upgrade -y] ++ $packages))] }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([eopkg search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([eopkg remove -y] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([eopkg info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([eopkg list-installed] ++ $packages))] }
                update => { [(_spm-cmd true [eopkg update-repo])] }
                clean => { [(_spm-cmd true [eopkg clean])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        swupd => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([swupd bundle-add] ++ $packages))]
                }
                upgrade => { [(_spm-cmd true ([swupd update] ++ $packages))] }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([swupd search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([swupd bundle-remove] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([swupd bundle-info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([swupd bundle-list] ++ $packages))] }
                update => { [(_spm-cmd true [swupd update --download])] }
                clean => { [(_spm-cmd true [swupd clean])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        pkg => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([pkg install -y] ++ $packages))]
                }
                upgrade => { [(_spm-cmd true ([pkg upgrade -y] ++ $packages))] }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([pkg search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([pkg delete -y] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([pkg info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([pkg info] ++ $packages))] }
                update => { [(_spm-cmd true [pkg update])] }
                clean => { [(_spm-cmd true [pkg clean -y])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        pkg_add => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([pkg_add] ++ $packages))]
                }
                upgrade => { [(_spm-cmd true ([pkg_add -u] ++ $packages))] }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false [pkg_info -Q (_spm-join $packages)])]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([pkg_delete] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([pkg_info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([pkg_info] ++ $packages))] }
                update => { [(_spm-cmd true [pkg_add -u])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        pkgin => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([pkgin -y install] ++ $packages))]
                }
                upgrade => { [(_spm-cmd true ([pkgin -y upgrade] ++ $packages))] }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([pkgin search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([pkgin -y remove] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([pkgin show-full-deps] ++ $packages))]
                }
                list => { [(_spm-cmd false ([pkgin list] ++ $packages))] }
                update => { [(_spm-cmd true [pkgin update])] }
                clean => { [(_spm-cmd true [pkgin clean])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        port => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([port install] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [
                            (_spm-cmd true [port selfupdate])
                            (_spm-cmd true [port upgrade outdated])
                        ]
                    } else {
                        [(_spm-cmd true ([port upgrade] ++ $packages))]
                    }
                }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([port search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd true ([port uninstall] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([port info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([port installed] ++ $packages))] }
                update => { [(_spm-cmd true [port selfupdate])] }
                clean => { [(_spm-cmd true [port clean --all all])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        winget => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([winget install --accept-package-agreements --accept-source-agreements] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [(_spm-cmd false [winget upgrade --all --accept-package-agreements --accept-source-agreements])]
                    } else {
                        [(_spm-cmd false ([winget upgrade --accept-package-agreements --accept-source-agreements] ++ $packages))]
                    }
                }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([winget search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([winget uninstall] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([winget show] ++ $packages))]
                }
                list => { [(_spm-cmd false ([winget list] ++ $packages))] }
                update => { [(_spm-cmd false [winget source update])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        scoop => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([scoop install] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [
                            (_spm-cmd false [scoop update])
                            (_spm-cmd false [scoop update '*'])
                        ]
                    } else {
                        [(_spm-cmd false ([scoop update] ++ $packages))]
                    }
                }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([scoop search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([scoop uninstall] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([scoop info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([scoop list] ++ $packages))] }
                update => { [(_spm-cmd false [scoop update])] }
                clean => { [(_spm-cmd false [scoop cleanup '*'])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        choco => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([choco install -y] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [(_spm-cmd false [choco upgrade all -y])]
                    } else {
                        [(_spm-cmd false ([choco upgrade -y] ++ $packages))]
                    }
                }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([choco search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([choco uninstall -y] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([choco info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([choco list --local-only] ++ $packages))] }
                update => { [(_spm-cmd false [choco outdated])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        nix-env => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([nix-env -iA] ++ $packages))]
                }
                upgrade => { [(_spm-cmd false ([nix-env -u] ++ $packages))] }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([nix-env -qaP] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([nix-env -e] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([nix-env -qa --description] ++ $packages))]
                }
                list => { [(_spm-cmd false ([nix-env -q] ++ $packages))] }
                update => { [(_spm-cmd false [nix-channel --update])] }
                clean => { [(_spm-cmd false [nix-collect-garbage -d])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        nix-profile => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([nix profile install] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [(_spm-cmd false [nix profile upgrade --all])]
                    } else {
                        [(_spm-cmd false ([nix profile upgrade] ++ $packages))]
                    }
                }
                search | info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false [nix search nixpkgs (_spm-join $packages)])]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([nix profile remove] ++ $packages))]
                }
                list => { [(_spm-cmd false ([nix profile list] ++ $packages))] }
                clean => { [(_spm-cmd false [nix store gc])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        nix => {
            match $action {
                search | info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false [nix search nixpkgs (_spm-join $packages)])]
                }
                list => { [(_spm-cmd false ([nix profile list] ++ $packages))] }
                clean => { [(_spm-cmd false [nix store gc])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        guix => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([guix install] ++ $packages))]
                }
                upgrade => { [(_spm-cmd false ([guix upgrade] ++ $packages))] }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([guix search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([guix remove] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([guix show] ++ $packages))]
                }
                list => { [(_spm-cmd false ([guix package --list-installed] ++ $packages))] }
                update => { [(_spm-cmd false [guix pull])] }
                clean => { [(_spm-cmd false [guix gc])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        conda => {
            match $action {
                install => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([conda install -y] ++ $packages))]
                }
                upgrade => {
                    if ($packages | is-empty) {
                        [(_spm-cmd false [conda update -y --all])]
                    } else {
                        [(_spm-cmd false ([conda update -y] ++ $packages))]
                    }
                }
                search => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([conda search] ++ $packages))]
                }
                remove => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([conda remove -y] ++ $packages))]
                }
                info => {
                    _spm-require-packages $action $packages
                    [(_spm-cmd false ([conda search --info] ++ $packages))]
                }
                list => { [(_spm-cmd false ([conda list] ++ $packages))] }
                update => { [(_spm-cmd false [conda update -y conda])] }
                clean => { [(_spm-cmd false [conda clean -a -y])] }
                _ => { _spm-unsupported $manager $action }
            }
        }
        _ => {
            error make {msg: $'spm: unsupported package manager: ($manager)'}
        }
    }
}

def _spm-needs-sudo [manager: string] {
    if (($env.SPM_NO_SUDO? | default '') == '1') {
        return false
    }

    let uid = (try { ^id -u | str trim } catch { '1' })
    if $uid == '0' {
        return false
    }

    ($manager in $spm_sudo_managers) and (_spm-command-exists sudo)
}

def _spm-display-argv [argv: list<string>] {
    $argv
    | each {|arg|
        if ($arg =~ '^[A-Za-z0-9_./:@%+=,-]+$') {
            $arg
        } else {
            $arg | to nuon
        }
    }
    | str join ' '
}

def _spm-run-commands [
    manager: string
    commands: list<record>
    --dry-run
] {
    for command in $commands {
        let argv = if $command.sudo and (_spm-needs-sudo $manager) {
            [sudo] ++ $command.argv
        } else {
            $command.argv
        }

        if $dry_run {
            print $'+ (_spm-display-argv $argv)'
        } else {
            let bin = ($argv | first)
            let args = ($argv | skip 1)
            run-external $bin ...$args
        }
    }
}

def _spm-action-alias [value: string] {
    match $value {
        install | add => 'install'
        upgrade | update-all => 'upgrade'
        search => 'search'
        remove | rm | uninstall => 'remove'
        info | show => 'info'
        list | ls => 'list'
        refresh => 'update'
        clean => 'clean'
        _ => ''
    }
}

def spm [
    ...packages: string
    --install(-i)      # install packages
    --upgrade(-u)      # upgrade packages, or all packages when none are given
    --search(-s)       # search packages
    --remove(-r)       # remove packages
    --info             # show package details
    --list(-l)         # list installed packages, optionally filtered by query
    --update           # refresh package indexes
    --clean            # clean package manager caches when supported
    --which            # print selected package manager
    --manager(-m): string
    --dry-run          # print commands without running them
    --help(-h)         # show help
]: nothing -> nothing {
    if $help {
        _spm-usage
        return
    }

    let selected = [
        {name: 'install', enabled: $install}
        {name: 'upgrade', enabled: $upgrade}
        {name: 'search', enabled: $search}
        {name: 'remove', enabled: $remove}
        {name: 'info', enabled: $info}
        {name: 'list', enabled: $list}
        {name: 'update', enabled: $update}
        {name: 'clean', enabled: $clean}
    ] | where enabled

    if (($selected | length) > 1) {
        error make {msg: 'spm: choose only one action'}
    }

    mut action = if ($selected | is-empty) { 'install' } else { $selected.0.name }
    mut rest = $packages

    if ($selected | is-empty) and (($rest | length) > 0) {
        let alias = (_spm-action-alias $rest.0)
        if ($alias | is-not-empty) {
            $action = $alias
            $rest = ($rest | skip 1)
        }
    }

    let selected_manager = if (($manager | default '') | is-not-empty) {
        $manager
    } else {
        _spm-detect-manager
    }

    if $which {
        print $selected_manager
        return
    }

    let commands = (_spm-build-commands $selected_manager $action $rest)
    _spm-run-commands $selected_manager $commands --dry-run=$dry_run
}
