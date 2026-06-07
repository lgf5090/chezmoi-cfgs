$script:IsWindowsPlatform = $false
$script:IsLinuxPlatform = $false
$script:IsMacOSPlatform = $false

try {
    $script:IsWindowsPlatform = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)
    $script:IsLinuxPlatform = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Linux)
    $script:IsMacOSPlatform = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::OSX)
} catch {
    $script:IsWindowsPlatform = $true
}

if ($script:IsWindowsPlatform) {
    $global:ShellsOS = 'windows'
} elseif ($script:IsMacOSPlatform) {
    $global:ShellsOS = 'macos'
} elseif ($script:IsLinuxPlatform) {
    $global:ShellsOS = 'linux'
} else {
    $global:ShellsOS = 'unknown'
}

if ($global:ShellsOS -eq 'linux' -and (Test-Path -LiteralPath '/proc/version')) {
    $procVersion = Get-Content -LiteralPath '/proc/version' -TotalCount 1 -ErrorAction SilentlyContinue
    if ($procVersion -match 'microsoft|wsl') {
        $global:ShellsOS = 'wsl'
    }
}

$env:SHELLS_OS = $global:ShellsOS
