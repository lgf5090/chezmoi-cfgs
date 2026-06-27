function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }
function l { Get-ChildItem @args }
function lt { Get-ChildItem -Force @args | Sort-Object -Property LastWriteTime -Descending }

function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

function md {
    param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function now { Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz' }
function cls { Clear-Host }
function reload { . (Join-Path $global:PowerShellConfigDir 'config.ps1') }

if ($global:ShellsOS -eq 'windows' -and -not (Test-Command grep)) {
    function grep {
        param(
            [Parameter(Position=0, Mandatory)][string]$Pattern,
            [Parameter(ValueFromRemainingArguments)][string[]]$Path
        )
        Select-String -Pattern $Pattern -Path ($(if ($Path) { $Path } else { '*' }))
    }
}

function dotfiles {
    $homePath = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
    git --git-dir (Join-Path $homePath '.dotfiles') --work-tree $homePath @args
}