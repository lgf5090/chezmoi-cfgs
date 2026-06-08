$homeDir = [Environment]::GetFolderPath('UserProfile')
$profileDir = Split-Path -Parent $PROFILE.CurrentUserCurrentHost

foreach ($completion in @(
    (Join-Path $env:XDG_DATA_HOME 'powershell/completions/poetry.ps1'),
    (Join-Path $profileDir 'completions/poetry.ps1'),
    (Join-Path $homeDir '.config/powershell/completions/poetry.ps1')
)) {
    if (-not (Test-Path -LiteralPath $completion -PathType Leaf)) { continue }
    . $completion
    break
}
