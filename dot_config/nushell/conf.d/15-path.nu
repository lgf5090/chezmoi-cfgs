mut path_append_dirs = [
    ($nu.home-dir | path join ".lmstudio" "bin")
    ($nu.home-dir | path join ".mimocode" "bin")
    ($nu.home-dir | path join ".turso")
    ($nu.home-dir | path join ".local" "bin")
    ($nu.home-dir | path join "bin")
    ($nu.home-dir | path join "Applications")
    ($nu.home-dir | path join ".local" "Applications")
]

# Tool installation dirs and language runtimes. Keeping these in one prepend
# avoids repeated PATH scans while preserving the previous priority order.
mut path_prepend_dirs = [
    (if (($env.ASDF_DIR? | default "") | is-empty) { "" } else { $env.ASDF_DIR | path join "bin" })
    (if (($env.RBENV_ROOT? | default "") | is-empty) { "" } else { $env.RBENV_ROOT | path join "bin" })
    (if (($env.NODENV_ROOT? | default "") | is-empty) { "" } else { $env.NODENV_ROOT | path join "bin" })
    (if (($env.GOENV_ROOT? | default "") | is-empty) { "" } else { $env.GOENV_ROOT | path join "bin" })
    (if (($env.JENV_ROOT? | default "") | is-empty) { "" } else { $env.JENV_ROOT | path join "bin" })
    ((if (($env.CARGO_HOME? | default "") | is-empty) { $nu.home-dir | path join ".cargo" } else { $env.CARGO_HOME }) | path join "bin")
    ($nu.home-dir | path join ".rd" "bin")
    ($nu.home-dir | path join ".opencode" "bin")
    (if (($env.BUN_INSTALL? | default "") | is-empty) { "" } else { $env.BUN_INSTALL | path join "bin" })
    (if (($env.DENO_INSTALL? | default "") | is-empty) { "" } else { $env.DENO_INSTALL | path join "bin" })
    (if (($env.NPM_CONFIG_PREFIX? | default "") | is-empty) { "" } else { $env.NPM_CONFIG_PREFIX | path join "bin" })
    ($env.PNPM_HOME? | default "")
    ($nu.home-dir | path join ".yarn" "bin")
    ($nu.home-dir | path join ".config" "yarn" "global" "node_modules" ".bin")
    (if (($env.VOLTA_HOME? | default "") | is-empty) { "" } else { $env.VOLTA_HOME | path join "bin" })
    ($nu.home-dir | path join ".volta" "bin")
    ($env.FNM_DIR? | default "")
    ($nu.home-dir | path join ".local" "share" "npm" "bin")
    (if (($env.PYENV_ROOT? | default "") | is-empty) { "" } else { $env.PYENV_ROOT | path join "bin" })
    (if (($env.ANACONDA_HOME? | default "") | is-empty) { "" } else { $env.ANACONDA_HOME | path join "bin" })
    (if (($env.POETRY_HOME? | default "") | is-empty) { "" } else { $env.POETRY_HOME | path join "bin" })
    ($nu.home-dir | path join ".poetry" "bin")
    ($nu.home-dir | path join ".local" "pipx" "bin")
    (if (($env.GOPATH? | default "") | is-empty) { "" } else { $env.GOPATH | path join "bin" })
    (if (($env.GOROOT? | default "") | is-empty) { "" } else { $env.GOROOT | path join "bin" })
]

if $env.SHELLS_OS in ["linux" "wsl"] {
    $path_append_dirs = ($path_append_dirs | append [
        "/snap/bin"
        "/var/lib/snapd/snap/bin"
        "/var/lib/flatpak/exports/bin"
        ($nu.home-dir | path join ".local" "share" "flatpak" "exports" "bin")
        "/opt/bin"
    ])
}

if $env.SHELLS_OS == "wsl" {
    $path_append_dirs = ($path_append_dirs | append [
        "/mnt/c/Program Files/Microsoft VS Code/bin"
        $"/mnt/c/Users/($env.USER? | default "")/AppData/Local/Programs/Microsoft VS Code/bin"
    ])
}

if $env.SHELLS_OS == "windows" {
    $path_prepend_dirs = ($path_prepend_dirs | append [
        ($nu.home-dir | path join "scoop" "shims")
        (if (($env.PROGRAMDATA? | default "") | is-empty) { "" } else { $env.PROGRAMDATA | path join "scoop" "shims" })
        (if (($env.PROGRAMDATA? | default "") | is-empty) { "" } else { $env.PROGRAMDATA | path join "chocolatey" "bin" })
        (if (($env.LOCALAPPDATA? | default "") | is-empty) { "" } else { $env.LOCALAPPDATA | path join "Microsoft" "WindowsApps" })
        (if (($env.APPDATA? | default "") | is-empty) { "" } else { $env.APPDATA | path join "npm" })
    ])
}

$path_prepend_dirs = ($path_prepend_dirs | append [
    ($nu.home-dir | path join ".nix-profile" "bin")
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
])

for brew in [
    "/home/linuxbrew/.linuxbrew/bin/brew"
    ($nu.home-dir | path join ".linuxbrew" "bin" "brew")
    "/opt/homebrew/bin/brew"
    "/usr/local/bin/brew"
] {
    if not ($brew | path exists) { continue }

    let brew_bin = ($brew | path dirname)
    let brew_prefix = ($brew_bin | path dirname)
    $path_prepend_dirs = ($path_prepend_dirs | append [
        ($brew_prefix | path join "bin")
        ($brew_prefix | path join "sbin")
    ])

    $env.HOMEBREW_PREFIX = $brew_prefix
    $env.HOMEBREW_CELLAR = ($brew_prefix | path join "Cellar")
    $env.HOMEBREW_REPOSITORY = if ($brew_prefix | path basename) == "Homebrew" {
        $brew_prefix
    } else {
        $brew_prefix | path join "Homebrew"
    }
    break
}

# Keep runtime-manager shims in the same priority order that the old 70-79
# path fragments produced, while still applying PATH only once.
$path_prepend_dirs = ($path_prepend_dirs | append [
    ($nu.home-dir | path join ".mise" "shims")
    (if (($env.MISE_DATA_DIR? | default "") | is-empty) { "" } else { $env.MISE_DATA_DIR | path join "shims" })
])

$path_prepend_dirs = ($path_prepend_dirs | append [
    (if (($env.ASDF_DIR? | default "") | is-empty) { "" } else { $env.ASDF_DIR | path join "bin" })
    (if (($env.ASDF_DATA_DIR? | default "") | is-empty) { "" } else { $env.ASDF_DATA_DIR | path join "shims" })
])

$path_prepend_dirs = ($path_prepend_dirs | append [
    (if (($env.PYENV_ROOT? | default "") | is-empty) { "" } else { $env.PYENV_ROOT | path join "bin" })
    (if (($env.PYENV_ROOT? | default "") | is-empty) { "" } else { $env.PYENV_ROOT | path join "shims" })
    (if (($env.PYENV_ROOT? | default "") | is-empty) { "" } else { $env.PYENV_ROOT | path join "pyenv-win" "bin" })
    (if (($env.PYENV_ROOT? | default "") | is-empty) { "" } else { $env.PYENV_ROOT | path join "pyenv-win" "shims" })
])

$path_prepend_dirs = ($path_prepend_dirs | append [
    ($env.FNM_DIR? | default "")
])

$path_prepend_dirs = ($path_prepend_dirs | append [
    (if (($env.RBENV_ROOT? | default "") | is-empty) { "" } else { $env.RBENV_ROOT | path join "bin" })
    (if (($env.RBENV_ROOT? | default "") | is-empty) { "" } else { $env.RBENV_ROOT | path join "shims" })
    (if (($env.NODENV_ROOT? | default "") | is-empty) { "" } else { $env.NODENV_ROOT | path join "bin" })
    (if (($env.NODENV_ROOT? | default "") | is-empty) { "" } else { $env.NODENV_ROOT | path join "shims" })
    (if (($env.GOENV_ROOT? | default "") | is-empty) { "" } else { $env.GOENV_ROOT | path join "bin" })
    (if (($env.GOENV_ROOT? | default "") | is-empty) { "" } else { $env.GOENV_ROOT | path join "shims" })
    (if (($env.JENV_ROOT? | default "") | is-empty) { "" } else { $env.JENV_ROOT | path join "bin" })
    (if (($env.JENV_ROOT? | default "") | is-empty) { "" } else { $env.JENV_ROOT | path join "shims" })
])

$path_prepend_dirs = ($path_prepend_dirs | append [
    (if (($env.ANACONDA_HOME? | default "") | is-empty) { "" } else { $env.ANACONDA_HOME | path join "bin" })
    (if (($env.ANACONDA_HOME? | default "") | is-empty) { "" } else { $env.ANACONDA_HOME | path join "condabin" })
])

$path_prepend_dirs = ($path_prepend_dirs | append [
    (if (($env.POETRY_HOME? | default "") | is-empty) { "" } else { $env.POETRY_HOME | path join "bin" })
])

_nu_path_append ...$path_append_dirs
_nu_path_prepend ...$path_prepend_dirs
