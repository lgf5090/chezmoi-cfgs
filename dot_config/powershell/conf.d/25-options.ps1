if ($PSVersionTable.PSVersion.Major -ge 7 -and $null -ne $PSStyle) {
    $PSStyle.OutputRendering = 'Host'
}

$ErrorView = 'ConciseView'
