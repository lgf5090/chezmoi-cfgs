function nvlz {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $previous = $env:NVIM_APPNAME
    try {
        $env:NVIM_APPNAME = 'nvim-lazy'
        & nvim @Arguments
    } finally {
        if ($null -eq $previous) {
            Remove-Item Env:NVIM_APPNAME -ErrorAction SilentlyContinue
        } else {
            $env:NVIM_APPNAME = $previous
        }
    }
}
