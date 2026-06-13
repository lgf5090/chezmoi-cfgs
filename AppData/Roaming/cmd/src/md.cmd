@echo off
:: md.cmd - Unix-style directory creation for Windows with brace expansion
:: Usage: md [OPTION]... DIRECTORY...
:: Options:
::   -v, --verbose        Explain what is being done
::   -h, --help           Display this help and exit
:: Supports brace expansion: md shell/{bash,zsh,fish} creates shell/bash, shell/zsh, shell/fish

setlocal enabledelayedexpansion

set "verbose=0"
set "dirs="
set "dir_count=0"

:: Get the entire command line and remove the script name
set "cmdline=%*"

:: Check for help
echo.%cmdline% | findstr /i "\-h \-\-help" >nul
if not errorlevel 1 goto :show_help

:: Check for verbose
echo.%cmdline% | findstr /i "\-v \-\-verbose" >nul
if not errorlevel 1 (
    set "verbose=1"
    set "cmdline=!cmdline:-v=!"
    set "cmdline=!cmdline:--verbose=!"
)

:: Trim spaces
for /f "tokens=*" %%a in ("!cmdline!") do set "cmdline=%%a"

:: Check if command line contains braces for expansion
echo.!cmdline! | findstr /r "{.*}" >nul 2>nul
if not errorlevel 1 (
    call :expand_braces "!cmdline!"
)

:check_args
:: Check if we have directories to create
if "%cmdline%"=="" (
    echo Error: missing operand
    echo Try 'md --help' for more information.
    exit /b 1
)

:: Process directories
if %dir_count%==0 (
    :: No brace expansion - process each space-separated argument
    for %%d in (!cmdline!) do (
        call :create_dir "%%~d"
    )
) else (
    :: Brace expansion - process pipe-separated list
    for %%d in ("%dirs:|=" "%") do (
        call :create_dir "%%~d"
    )
)

endlocal
exit /b 0

:: Function to expand braces like shell/{bash,zsh,fish}
:expand_braces
set "pattern=%~1"

:: Extract everything before {
set "before="
set "rest="

:: Find position of first {
for /f "delims={" %%a in ("%pattern%") do set "before=%%a"

:: Extract the part after the opening brace using string substitution
setlocal enabledelayedexpansion
set "temp=!pattern!"
call set "rest=%%temp:*{=%%"

:: Extract choices (before }) and after part
set "choices="
set "after="

for /f "delims=}" %%a in ("!rest!") do set "choices=%%a"
call set "after=%%rest:*}=%%"

:: Handle case where after part equals rest (no closing brace found)
if "!after!"=="!rest!" set "after="

endlocal & set "before=%before%" & set "choices=%choices%" & set "after=%after%"

:: Reset dirs and dir_count since we're expanding
set "dirs="
set "dir_count=0"

:: Expand each choice (comma-separated)
call :split_and_expand "%choices%" "%before%" "%after%"

exit /b 0

:split_and_expand
set "choice_list=%~1"
set "prefix=%~2"
set "suffix=%~3"

:: Replace commas with spaces for iteration
set "choice_list=%choice_list:,= %"

:: Expand each choice
for %%c in (%choice_list%) do (
    set "expanded=%prefix%%%c%suffix%"
    if not defined dirs (
        set "dirs=!expanded!"
    ) else (
        set "dirs=!dirs!|!expanded!"
    )
    set /a dir_count+=1
)

exit /b 0

:: Function to create a directory (like mkdir -p)
:create_dir
set "target=%~1"

:: Skip empty targets
if not defined target exit /b 0
if "%target%"=="" exit /b 0

:: Check if directory already exists
if exist "%target%\" (
    if %verbose%==1 echo Directory already exists: '%target%'
    exit /b 0
)

:: Create directory with parent directories
if %verbose%==1 echo Creating directory: '%target%'
mkdir "%target%" >nul 2>nul

if errorlevel 1 (
    echo Error: cannot create directory '%target%': Permission denied or invalid path
    exit /b 1
)

exit /b 0

:show_help
echo Usage: md [OPTION]... DIRECTORY...
echo Create directories (with parent directories as needed).
echo.
echo Options:
echo   -v, --verbose        Explain what is being done
echo   -h, --help           Display this help and exit
echo.
echo This command always creates parent directories (like mkdir -p).
echo.
echo Brace expansion is supported:
echo   md shell/{bash,zsh,fish}    Creates shell/bash, shell/zsh, shell/fish
echo.
echo Examples:
echo   md mydir                    Create a directory
echo   md path/to/deep/dir         Create directory with parents
echo   md -v shell/{bash,zsh}      Create multiple directories with verbose output
exit /b 0
