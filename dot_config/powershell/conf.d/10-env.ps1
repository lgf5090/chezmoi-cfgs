if ([string]::IsNullOrWhiteSpace($env:EDITOR)) { $env:EDITOR = 'vim' }
if ([string]::IsNullOrWhiteSpace($env:VISUAL)) { $env:VISUAL = $env:EDITOR }
if ([string]::IsNullOrWhiteSpace($env:PAGER)) { $env:PAGER = 'less' }
if ([string]::IsNullOrWhiteSpace($env:LESS)) { $env:LESS = '-R -F -X' }
if ([string]::IsNullOrWhiteSpace($env:CLICOLOR)) { $env:CLICOLOR = '1' }
