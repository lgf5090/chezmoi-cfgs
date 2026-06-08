$homeDir = [Environment]::GetFolderPath('UserProfile')

if ([string]::IsNullOrWhiteSpace($env:SDKMAN_DIR)) {
    $env:SDKMAN_DIR = Join-Path $homeDir '.sdkman'
}

$sdkmanPowerShellInit = Join-Path $env:SDKMAN_DIR 'bin/sdkman-init.ps1'
if (Test-Path -LiteralPath $sdkmanPowerShellInit -PathType Leaf) {
    . $sdkmanPowerShellInit
}
