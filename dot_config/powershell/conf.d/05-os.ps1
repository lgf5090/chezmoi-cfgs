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

if ($global:ShellsOS -eq 'linux' -and [System.IO.File]::Exists('/proc/version')) {
    $reader = [System.IO.File]::OpenText('/proc/version')
    try {
        $procVersion = $reader.ReadLine()
    } finally {
        $reader.Dispose()
    }
    if ($procVersion -and (
        $procVersion.IndexOf('microsoft', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or
        $procVersion.IndexOf('wsl', [System.StringComparison]::OrdinalIgnoreCase) -ge 0
    )) {
        $global:ShellsOS = 'wsl'
    }
}

$env:SHELLS_OS = $global:ShellsOS
