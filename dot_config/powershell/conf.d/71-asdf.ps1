if (-not [string]::IsNullOrWhiteSpace($env:ASDF_DIR)) {
    Add-PathPrepend (Join-Path $env:ASDF_DIR 'bin')
}

if (-not [string]::IsNullOrWhiteSpace($env:ASDF_DATA_DIR)) {
    Add-PathPrepend (Join-Path $env:ASDF_DATA_DIR 'shims')
}
