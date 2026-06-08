if (-not [string]::IsNullOrWhiteSpace($env:ANACONDA_HOME) -and
    (Test-Path -LiteralPath (Join-Path $env:ANACONDA_HOME 'bin/conda') -PathType Leaf)) {
    $script:PowerShellCondaExe = Join-Path $env:ANACONDA_HOME 'bin/conda'
} elseif (Test-Command conda) {
    $script:PowerShellCondaExe = (Get-Command conda -ErrorAction SilentlyContinue).Source
}

if (-not [string]::IsNullOrWhiteSpace($script:PowerShellCondaExe)) {
    function Initialize-PowerShellConda {
        Remove-Item Function:\conda -ErrorAction SilentlyContinue
        Remove-Item Function:\mamba -ErrorAction SilentlyContinue
        Remove-Item Function:\Initialize-PowerShellConda -ErrorAction SilentlyContinue

        $hook = & $script:PowerShellCondaExe shell.powershell hook 2>$null
        if (-not [string]::IsNullOrWhiteSpace(($hook | Out-String))) {
            Invoke-Expression ($hook | Out-String)
        } elseif (-not [string]::IsNullOrWhiteSpace($env:ANACONDA_HOME) -and
            (Test-Path -LiteralPath (Join-Path $env:ANACONDA_HOME 'shell/condabin/Conda.psm1') -PathType Leaf)) {
            Import-Module (Join-Path $env:ANACONDA_HOME 'shell/condabin/Conda.psm1') -Global -ErrorAction SilentlyContinue
        } else {
            Add-PathPrepend (Split-Path -Parent $script:PowerShellCondaExe)
        }
    }

    function global:conda {
        Initialize-PowerShellConda
        conda @args
    }

    if (Test-Command mamba) {
        function global:mamba {
            Initialize-PowerShellConda
            mamba @args
        }
    }
}

if (Test-Command micromamba) {
    $script:PowerShellMicromambaExe = (Get-Command micromamba -ErrorAction SilentlyContinue).Source

    function global:micromamba {
        Remove-Item Function:\micromamba -ErrorAction SilentlyContinue

        $hook = & $script:PowerShellMicromambaExe shell hook --shell powershell 2>$null
        if (-not [string]::IsNullOrWhiteSpace(($hook | Out-String))) {
            Invoke-Expression ($hook | Out-String)
        }
        micromamba @args
    }
}
