$historyDir = Join-Path $env:XDG_STATE_HOME 'powershell'
$historyFile = Join-Path $historyDir 'history.txt'
if (-not [System.IO.Directory]::Exists($historyDir)) {
    [System.IO.Directory]::CreateDirectory($historyDir) | Out-Null
}

$loadPSReadLine = (
    $env:POWERSHELL_LOAD_PSREADLINE -eq '1' -or (
        $env:POWERSHELL_LOAD_PSREADLINE -ne '0' -and
        -not [Console]::IsInputRedirected -and
        -not [Console]::IsOutputRedirected
    )
)

if ($loadPSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
}

if ($loadPSReadLine -and (Get-Module -Name PSReadLine)) {
    Set-PSReadLineOption -HistorySavePath $historyFile -HistorySaveStyle SaveIncrementally -ErrorAction SilentlyContinue
}
