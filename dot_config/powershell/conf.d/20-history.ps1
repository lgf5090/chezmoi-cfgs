$historyDir = Join-Path $env:XDG_STATE_HOME 'powershell'
$historyFile = Join-Path $historyDir 'history.txt'
New-Item -ItemType Directory -Force -Path $historyDir | Out-Null

if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
        Set-PSReadLineOption -HistorySavePath $historyFile -ErrorAction SilentlyContinue
        Set-PSReadLineOption -HistorySaveStyle SaveIncrementally -ErrorAction SilentlyContinue
    }
}
