if (-not (Get-Module -Name PSReadLine)) {
    return
}

$PSReadLineOpts = @{
    EditMode                      = 'Vi'
    BellStyle                     = 'None'
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    PredictionSource              = 'History'
    PredictionViewStyle           = 'ListView'
    MaximumHistoryCount           = 10000
    HistorySaveStyle              = 'SaveIncrementally'
}

$__psrl_hist_dir = if ($env:XDG_STATE_HOME) {
    Join-Path $env:XDG_STATE_HOME 'powershell'
} else {
    Join-Path $HOME '.local/state/powershell'
}

if (-not [System.IO.Directory]::Exists($__psrl_hist_dir)) {
    $null = New-Item -ItemType Directory -Path $__psrl_hist_dir -Force -ErrorAction Ignore
}

$PSReadLineOpts['HistorySavePath'] = Join-Path $__psrl_hist_dir 'PSReadLineHistory.txt'
Remove-Variable __psrl_hist_dir -ErrorAction Ignore

Set-PSReadLineOption @PSReadLineOpts -ErrorAction Ignore
Remove-Variable PSReadLineOpts -ErrorAction Ignore

Set-PSReadLineOption -AddToHistoryHandler {
    param($line)

    if ($line -match '(?i)(password|secret|token|api[_-]?key)\s*[=:]') {
        return 'MemoryOnly'
    }

    return 'MemoryAndFile'
} -ErrorAction Ignore

# Ctrl+f is reserved for fzf in 60-fzf.ps1.
$__shells_vi_insert = [ordered]@{
    'Ctrl+a'         = 'BeginningOfLine'
    'Ctrl+e'         = 'EndOfLine'
    'Ctrl+x,Ctrl+f'  = 'ForwardChar'
    'Ctrl+b'         = 'BackwardChar'
    'Ctrl+d'         = 'DeleteChar'
    'Ctrl+h'         = 'BackwardDeleteChar'
    'Ctrl+k'         = 'ForwardDeleteLine'
    'Ctrl+u'         = 'BackwardDeleteLine'
    'Ctrl+w'         = 'BackwardKillWord'
    'Ctrl+y'         = 'Yank'
    'Ctrl+r'         = 'ReverseSearchHistory'
    'Ctrl+s'         = 'ForwardSearchHistory'
    'Ctrl+p'         = 'PreviousHistory'
    'Ctrl+n'         = 'NextHistory'
    'Ctrl+l'         = 'ClearScreen'
    'Ctrl+z'         = 'Undo'
    'Alt+f'          = 'ForwardWord'
    'Alt+b'          = 'BackwardWord'
    'Alt+d'          = 'KillWord'
    'Alt+Backspace'  = 'BackwardKillWord'
    'Alt+.'          = 'YankLastArg'
    'Tab'            = 'Complete'
    'Ctrl+t'         = 'SwapCharacters'
    'Alt+u'          = 'UpcaseWord'
    'Alt+l'          = 'DowncaseWord'
    'Alt+c'          = 'CapitalizeWord'
    'UpArrow'        = 'HistorySearchBackward'
    'DownArrow'      = 'HistorySearchForward'
    'Home'           = 'BeginningOfLine'
    'End'            = 'EndOfLine'
    'PageUp'         = 'HistorySearchBackward'
    'PageDown'       = 'HistorySearchForward'
    'Delete'         = 'DeleteChar'
    'Ctrl+LeftArrow'  = 'BackwardWord'
    'Ctrl+RightArrow' = 'ForwardWord'
}

$__shells_vi_command = [ordered]@{
    'Ctrl+a'         = 'BeginningOfLine'
    'Ctrl+e'         = 'EndOfLine'
    'Ctrl+x,Ctrl+f'  = 'ForwardChar'
    'Ctrl+b'         = 'BackwardChar'
    'Ctrl+d'         = 'DeleteChar'
    'Ctrl+k'         = 'ForwardDeleteLine'
    'Ctrl+u'         = 'BackwardDeleteLine'
    'Ctrl+w'         = 'BackwardKillWord'
    'Ctrl+y'         = 'Yank'
    'Ctrl+r'         = 'ReverseSearchHistory'
    'Ctrl+s'         = 'ForwardSearchHistory'
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
    'Ctrl+LeftArrow'  = 'BackwardWord'
    'Ctrl+RightArrow' = 'ForwardWord'
}

foreach ($entry in $__shells_vi_insert.GetEnumerator()) {
    try {
        Set-PSReadLineKeyHandler -Chord $entry.Key -ViMode Insert -Function $entry.Value -ErrorAction Stop
    } catch {
    }
}

foreach ($entry in $__shells_vi_command.GetEnumerator()) {
    try {
        Set-PSReadLineKeyHandler -Chord $entry.Key -ViMode Command -Function $entry.Value -ErrorAction Stop
    } catch {
    }
}

Remove-Variable -Name __shells_vi_insert, __shells_vi_command -Scope Script -ErrorAction Ignore
