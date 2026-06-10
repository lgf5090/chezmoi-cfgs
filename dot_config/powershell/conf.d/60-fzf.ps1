& {
function Find-FzfTool {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$Path
    )

    foreach ($candidate in $Path) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        if (-not [System.IO.File]::Exists($candidate)) { continue }
        return [System.IO.Path]::GetFullPath($candidate)
    }

    if ($env:POWERSHELL_FZF_DISCOVERY -eq '1') {
        return (Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue).Source
    }

    $null
}

$homeDir = [Environment]::GetFolderPath('UserProfile')
$brewPrefix = $env:HOMEBREW_PREFIX

$global:PowerShellFdExe = Find-FzfTool -Name 'fd' -Path @(
    (Join-Path $homeDir '.local/bin/fd'),
    $(if ($brewPrefix) { Join-Path $brewPrefix 'bin/fd' }),
    '/home/linuxbrew/.linuxbrew/bin/fd',
    (Join-Path $homeDir '.linuxbrew/bin/fd'),
    '/opt/homebrew/bin/fd',
    '/usr/local/bin/fd',
    '/usr/bin/fd',
    '/usr/bin/fdfind'
)
$global:PowerShellBatExe = Find-FzfTool -Name 'bat' -Path @(
    (Join-Path $homeDir '.local/bin/bat'),
    $(if ($brewPrefix) { Join-Path $brewPrefix 'bin/bat' }),
    '/home/linuxbrew/.linuxbrew/bin/bat',
    (Join-Path $homeDir '.linuxbrew/bin/bat'),
    '/opt/homebrew/bin/bat',
    '/usr/local/bin/bat',
    '/usr/bin/bat',
    '/usr/bin/batcat'
)
$global:PowerShellFzfExe = Find-FzfTool -Name 'fzf' -Path @(
    (Join-Path $homeDir '.local/bin/fzf'),
    $(if ($brewPrefix) { Join-Path $brewPrefix 'bin/fzf' }),
    '/home/linuxbrew/.linuxbrew/bin/fzf',
    (Join-Path $homeDir '.linuxbrew/bin/fzf'),
    '/opt/homebrew/bin/fzf',
    '/usr/local/bin/fzf',
    '/usr/bin/fzf'
)
}

if (-not [string]::IsNullOrWhiteSpace($global:PowerShellFdExe)) {
    $fdName = [System.IO.Path]::GetFileNameWithoutExtension($global:PowerShellFdExe)
    $env:FZF_DEFAULT_COMMAND = "$fdName --type f --hidden --strip-cwd-prefix"
} else {
    $env:FZF_DEFAULT_COMMAND = ''
}

$env:FZF_CTRL_T_COMMAND = $env:FZF_DEFAULT_COMMAND
$env:FZF_DEFAULT_OPTS = '--height=60% --layout=reverse --border=rounded --preview-window=right:65%:wrap:border-left'

if (-not [string]::IsNullOrWhiteSpace($global:PowerShellBatExe)) {
    $batName = [System.IO.Path]::GetFileNameWithoutExtension($global:PowerShellBatExe)
    $env:_FZF_PREVIEW_CMD = "$batName --color=always --style=plain,numbers --line-range=:500 {}"
} else {
    $env:_FZF_PREVIEW_CMD = ''
}

function Invoke-FzfFileNoHidden {
    if ([string]::IsNullOrWhiteSpace($global:PowerShellFzfExe)) { return }

    if (-not [string]::IsNullOrWhiteSpace($global:PowerShellFdExe)) {
        $items = & $global:PowerShellFdExe --type f --strip-cwd-prefix
    } else {
        $items = Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object { Resolve-Path -LiteralPath $_.FullName -Relative }
    }

    $fzfArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($env:_FZF_PREVIEW_CMD)) {
        $fzfArgs += @('--preview', $env:_FZF_PREVIEW_CMD)
    }

    $selected = $items | & $global:PowerShellFzfExe @fzfArgs
    if ([string]::IsNullOrWhiteSpace($selected)) { return }

    if ([type]::GetType('Microsoft.PowerShell.PSConsoleReadLine', $false)) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected)
    } else {
        $selected
    }
}

if ($global:PowerShellPSReadLineLoaded -and -not [string]::IsNullOrWhiteSpace($global:PowerShellFzfExe)) {
    Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -ScriptBlock { Invoke-FzfFileNoHidden } -ErrorAction SilentlyContinue
}
