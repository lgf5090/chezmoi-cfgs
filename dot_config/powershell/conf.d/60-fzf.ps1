if (Test-Command fd) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --strip-cwd-prefix'
} else {
    $env:FZF_DEFAULT_COMMAND = ''
}

$env:FZF_CTRL_T_COMMAND = $env:FZF_DEFAULT_COMMAND
$env:FZF_DEFAULT_OPTS = '--height=60% --layout=reverse --border=rounded --preview-window=right:65%:wrap:border-left'

if (Test-Command bat) {
    $env:_FZF_PREVIEW_CMD = 'bat --color=always --style=plain,numbers --line-range=:500 {}'
} elseif (Test-Command batcat) {
    $env:_FZF_PREVIEW_CMD = 'batcat --color=always --style=plain,numbers --line-range=:500 {}'
} else {
    $env:_FZF_PREVIEW_CMD = ''
}

function Invoke-FzfFileNoHidden {
    if (-not (Test-Command fzf)) { return }

    if (Test-Command fd) {
        $items = fd --type f --strip-cwd-prefix
    } else {
        $items = Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object { Resolve-Path -LiteralPath $_.FullName -Relative }
    }

    $fzfArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($env:_FZF_PREVIEW_CMD)) {
        $fzfArgs += @('--preview', $env:_FZF_PREVIEW_CMD)
    }

    $selected = $items | fzf @fzfArgs
    if ([string]::IsNullOrWhiteSpace($selected)) { return }

    if ([type]::GetType('Microsoft.PowerShell.PSConsoleReadLine', $false)) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected)
    } else {
        $selected
    }
}

if ((Test-Command fzf) -and (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue)) {
    Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -ScriptBlock { Invoke-FzfFileNoHidden } -ErrorAction SilentlyContinue
}
