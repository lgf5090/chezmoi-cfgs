$lfIcons = Join-Path $env:XDG_CONFIG_HOME 'lf/icons'
if (Test-Path -LiteralPath $lfIcons -PathType Leaf) {
    $env:LF_ICONS = ((Get-Content -LiteralPath $lfIcons) -join ':') + ':'
}

if (Test-Command lf) {
    function lf {
        $tmp = [IO.Path]::GetTempFileName()
        try {
            & (Get-Command lf -CommandType Application).Source "-last-dir-path=$tmp" @args
            $rc = $LASTEXITCODE

            if (Test-Path -LiteralPath $tmp -PathType Leaf) {
                $dir = Get-Content -LiteralPath $tmp -Raw
                $dir = $dir.Trim()
                if ($dir -and (Test-Path -LiteralPath $dir -PathType Container) -and $dir -ne (Get-Location).ProviderPath) {
                    Set-Location -LiteralPath $dir
                }
            }

            if ($rc -ne 0) { $global:LASTEXITCODE = $rc }
        } finally {
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        }
    }
}
