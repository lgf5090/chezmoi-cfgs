function global:mcc {
    Remove-Item Function:\mcc -ErrorAction SilentlyContinue
    . (Join-Path $global:PowerShellConfigDir 'lib/mcc.ps1')
    mcc @args
}
