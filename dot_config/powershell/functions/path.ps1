function path {
    $env:PATH -split [Regex]::Escape([IO.Path]::PathSeparator)
}
