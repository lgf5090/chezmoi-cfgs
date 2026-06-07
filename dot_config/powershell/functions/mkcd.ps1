function mkcd {
    param([Parameter(Position=0)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Error 'usage: mkcd <dir>'
        return
    }

    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Location -LiteralPath $Path
}
