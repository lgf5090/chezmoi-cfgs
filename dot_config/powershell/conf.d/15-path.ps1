$homeDir = [Environment]::GetFolderPath('UserProfile')
$cargoHome = if ($env:CARGO_HOME) { $env:CARGO_HOME } else { Join-Path $homeDir '.cargo' }

$pathAppend = @(
    Join-Path $homeDir '.lmstudio/bin'
    Join-Path $homeDir '.mimocode/bin'
    Join-Path $homeDir '.local/bin'
    Join-Path $homeDir 'bin'
    Join-Path $homeDir 'Applications'
    Join-Path $homeDir '.local/Applications'
)

$pathPrepend = @(
    if ($env:ASDF_DIR) { Join-Path $env:ASDF_DIR 'bin' }
    if ($env:RBENV_ROOT) { Join-Path $env:RBENV_ROOT 'bin' }
    if ($env:NODENV_ROOT) { Join-Path $env:NODENV_ROOT 'bin' }
    if ($env:GOENV_ROOT) { Join-Path $env:GOENV_ROOT 'bin' }
    if ($env:JENV_ROOT) { Join-Path $env:JENV_ROOT 'bin' }
    Join-Path $cargoHome 'bin'
    Join-Path $homeDir '.rd/bin'
    Join-Path $homeDir '.opencode/bin'
)

$cargoEnv = Join-Path $homeDir '.cargo/env.ps1'
if ($env:POWERSHELL_SOURCE_CARGO_ENV -eq '1' -and [System.IO.File]::Exists($cargoEnv)) {
    . $cargoEnv
}

$pathPrepend += @(
    if ($env:BUN_INSTALL) { Join-Path $env:BUN_INSTALL 'bin' }
    if ($env:DENO_INSTALL) { Join-Path $env:DENO_INSTALL 'bin' }
    if ($env:NPM_CONFIG_PREFIX) { Join-Path $env:NPM_CONFIG_PREFIX 'bin' }
    if ($env:PNPM_HOME) { $env:PNPM_HOME }
    Join-Path $homeDir '.yarn/bin'
    Join-Path $homeDir '.config/yarn/global/node_modules/.bin'
    if ($env:VOLTA_HOME) { Join-Path $env:VOLTA_HOME 'bin' }
    Join-Path $homeDir '.volta/bin'
    if ($env:FNM_DIR) { $env:FNM_DIR }
    Join-Path $homeDir '.local/share/npm/bin'
)

$pathPrepend += @(
    if ($env:PYENV_ROOT) { Join-Path $env:PYENV_ROOT 'bin' }
    if ($env:ANACONDA_HOME) { Join-Path $env:ANACONDA_HOME 'bin' }
    if ($env:POETRY_HOME) { Join-Path $env:POETRY_HOME 'bin' }
    Join-Path $homeDir '.poetry/bin'
    Join-Path $homeDir '.local/pipx/bin'
)

$pathPrepend += @(
    if ($env:GOPATH) { Join-Path $env:GOPATH 'bin' }
    if ($env:GOROOT) { Join-Path $env:GOROOT 'bin' }
)

switch ($global:ShellsOS) {
    { $_ -in @('linux', 'wsl') } {
        $pathAppend += @(
            '/snap/bin'
            '/var/lib/snapd/snap/bin'
            '/var/lib/flatpak/exports/bin'
            Join-Path $homeDir '.local/share/flatpak/exports/bin'
            '/opt/bin'
        )
    }
}

switch ($global:ShellsOS) {
    'wsl' {
        $pathAppend += @(
            '/mnt/c/Program Files/Microsoft VS Code/bin'
            "/mnt/c/Users/$env:USER/AppData/Local/Programs/Microsoft VS Code/bin"
        )
    }
    'windows' {
        $pathPrepend += @(
            Join-Path $homeDir 'scoop/shims'
            if ($env:PROGRAMDATA) { Join-Path $env:PROGRAMDATA 'scoop/shims' }
            if ($env:PROGRAMDATA) { Join-Path $env:PROGRAMDATA 'chocolatey/bin' }
            if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'Microsoft/WindowsApps' }
            if ($env:APPDATA) { Join-Path $env:APPDATA 'npm' }
        )
    }
}

$pathPrepend += @(
    Join-Path $homeDir '.nix-profile/bin'
    '/run/current-system/sw/bin'
    '/nix/var/nix/profiles/default/bin'
)

foreach ($brew in @(
    '/home/linuxbrew/.linuxbrew/bin/brew',
    (Join-Path $homeDir '.linuxbrew/bin/brew'),
    '/opt/homebrew/bin/brew',
    '/usr/local/bin/brew'
)) {
    if (-not (Test-Path -LiteralPath $brew -PathType Leaf)) { continue }

    $brewBin = Split-Path -Parent $brew
    $brewPrefix = Split-Path -Parent $brewBin
    $pathPrepend += @(
        Join-Path $brewPrefix 'bin'
        Join-Path $brewPrefix 'sbin'
    )
    $env:HOMEBREW_PREFIX = $brewPrefix
    $env:HOMEBREW_CELLAR = Join-Path $brewPrefix 'Cellar'
    $env:HOMEBREW_REPOSITORY = if ((Split-Path -Leaf $brewPrefix) -eq 'Homebrew') {
        $brewPrefix
    } else {
        Join-Path $brewPrefix 'Homebrew'
    }
    break
}

$pathPrepend += @(
    Join-Path $homeDir '.mise/shims'
    if ($env:MISE_DATA_DIR) { Join-Path $env:MISE_DATA_DIR 'shims' }
    if ($env:ASDF_DIR) { Join-Path $env:ASDF_DIR 'bin' }
    if ($env:ASDF_DATA_DIR) { Join-Path $env:ASDF_DATA_DIR 'shims' }
    if ($env:PYENV_ROOT) { Join-Path $env:PYENV_ROOT 'bin' }
    if ($env:PYENV_ROOT) { Join-Path $env:PYENV_ROOT 'shims' }
    if ($env:PYENV_ROOT) { Join-Path $env:PYENV_ROOT 'pyenv-win/bin' }
    if ($env:PYENV_ROOT) { Join-Path $env:PYENV_ROOT 'pyenv-win/shims' }
    if ($env:FNM_DIR) { $env:FNM_DIR }
    if ($env:FNM_DIR) { Join-Path $env:FNM_DIR 'aliases/default/bin' }
)

Add-PathAppend @pathAppend
Add-PathPrepend @pathPrepend
