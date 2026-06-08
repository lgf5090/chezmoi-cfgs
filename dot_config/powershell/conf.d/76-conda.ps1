$homeDir = [Environment]::GetFolderPath('UserProfile')

$condaCandidates = @()
if (-not [string]::IsNullOrWhiteSpace($env:ANACONDA_HOME)) {
    $condaCandidates += @(
        (Join-Path $env:ANACONDA_HOME 'bin/conda'),
        (Join-Path $env:ANACONDA_HOME 'condabin/conda'),
        (Join-Path $env:ANACONDA_HOME 'Scripts/conda.exe'),
        (Join-Path $env:ANACONDA_HOME 'condabin/conda.bat')
    )
}
$condaCandidates += @(
    (Join-Path $homeDir 'miniconda3/bin/conda'),
    (Join-Path $homeDir 'miniconda3/condabin/conda'),
    (Join-Path $homeDir 'anaconda3/bin/conda'),
    (Join-Path $homeDir 'anaconda3/condabin/conda'),
    '/opt/miniconda3/bin/conda',
    '/opt/miniconda3/condabin/conda',
    '/opt/anaconda3/bin/conda',
    '/opt/anaconda3/condabin/conda'
)

foreach ($candidate in $condaCandidates) {
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
    $script:PowerShellCondaExe = (Resolve-Path -LiteralPath $candidate).ProviderPath
    break
}

if ([string]::IsNullOrWhiteSpace($script:PowerShellCondaExe) -and $env:POWERSHELL_CONDA_DISCOVERY -eq '1') {
    $script:PowerShellCondaExe = (Get-Command conda -CommandType Application -ErrorAction SilentlyContinue).Source
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

    function global:mamba {
        Initialize-PowerShellConda
        mamba @args
    }
}

$micromambaCandidates = @(
    (Join-Path $homeDir '.local/bin/micromamba'),
    '/home/linuxbrew/.linuxbrew/bin/micromamba',
    (Join-Path $homeDir '.linuxbrew/bin/micromamba'),
    '/opt/homebrew/bin/micromamba',
    '/usr/local/bin/micromamba'
)
foreach ($candidate in $micromambaCandidates) {
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
    $script:PowerShellMicromambaExe = (Resolve-Path -LiteralPath $candidate).ProviderPath
    break
}

if ([string]::IsNullOrWhiteSpace($script:PowerShellMicromambaExe) -and $env:POWERSHELL_CONDA_DISCOVERY -eq '1') {
    $script:PowerShellMicromambaExe = (Get-Command micromamba -CommandType Application -ErrorAction SilentlyContinue).Source
}

if (-not [string]::IsNullOrWhiteSpace($script:PowerShellMicromambaExe)) {
    function global:micromamba {
        Remove-Item Function:\micromamba -ErrorAction SilentlyContinue

        $hook = & $script:PowerShellMicromambaExe shell hook --shell powershell 2>$null
        if (-not [string]::IsNullOrWhiteSpace(($hook | Out-String))) {
            Invoke-Expression ($hook | Out-String)
        }
        micromamba @args
    }
}
