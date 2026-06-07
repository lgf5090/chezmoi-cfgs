if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -EditMode Vi -ErrorAction SilentlyContinue
}

if (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Chord 'Ctrl+a' -Function BeginningOfLine -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Ctrl+e' -Function EndOfLine -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord -ErrorAction SilentlyContinue
}
