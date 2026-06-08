$historyDir = Join-Path $env:XDG_STATE_HOME 'powershell'
$historyFile = Join-Path $historyDir 'history.txt'
if (-not [System.IO.Directory]::Exists($historyDir)) {
    [System.IO.Directory]::CreateDirectory($historyDir) | Out-Null
}

Import-Module PSReadLine -ErrorAction SilentlyContinue
if (Get-Module -Name PSReadLine) {
    Set-PSReadLineOption -HistorySavePath $historyFile -HistorySaveStyle SaveIncrementally -ErrorAction SilentlyContinue
}
