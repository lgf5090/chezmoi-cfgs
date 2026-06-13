@echo off
:: Alias definitions - Windows version (Fastest version)
:: Corresponds to PowerShell's 03-aliases.ps1

:: Load predefined macros file directly
set "ALIASES_FILE=%USERPROFILE%\.config\cmd\aliases.txt"

if exist "%ALIASES_FILE%" (
    doskey /macrofile="%ALIASES_FILE%" 2>nul
) else (
    echo Warning: Aliases file not found: %ALIASES_FILE%
    echo Please create %ALIASES_FILE% file
)