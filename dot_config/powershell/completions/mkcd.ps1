Register-ArgumentCompleter -CommandName mkcd -ScriptBlock {
    param($CommandName, $ParameterName, $WordToComplete)

    Get-ChildItem -Directory -Path "$WordToComplete*" -ErrorAction SilentlyContinue |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_.FullName,
                $_.Name,
                'ParameterValue',
                $_.FullName
            )
        }
}
