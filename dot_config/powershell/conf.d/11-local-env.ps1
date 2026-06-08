if ($global:PowerShellLocalLoaderVersion -ne 1) {
    . (Join-Path $PSScriptRoot '01-helpers.ps1')
}

$localEnvFile = if ([string]::IsNullOrWhiteSpace($env:POWERSHELL_LOCAL_ENVS_FILE)) {
    Join-Path $HOME '.envs'
} else {
    $env:POWERSHELL_LOCAL_ENVS_FILE
}

if ([System.IO.File]::Exists($localEnvFile)) {
    foreach ($lineRaw in [System.IO.File]::ReadLines($localEnvFile)) {
        $line = $lineRaw.TrimStart()
        if ([string]::IsNullOrEmpty($line) -or $line[0] -eq '#') {
            continue
        }
        if ($line.StartsWith('export ')) {
            $line = $line.Substring(6).TrimStart()
        }

        $eq = $line.IndexOf('=')
        if ($eq -lt 1) {
            continue
        }

        $key = $line.Substring(0, $eq).TrimEnd()
        $value = $line.Substring($eq + 1).Trim()
        if ($key -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
            continue
        }

        if ($value.Length -ge 2) {
            $first = $value[0]
            $last = $value[$value.Length - 1]
            if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
                $value = $value.Substring(1, $value.Length - 2)
            }
        }

        $value = $value.Replace('{HOME}', $HOME).Replace('{PATH}', $env:PATH)
        if ($key -eq 'PATH') {
            Add-PathPrependValue -Value $value
        } else {
            [System.Environment]::SetEnvironmentVariable($key, $value, 'Process')
        }
    }
}
