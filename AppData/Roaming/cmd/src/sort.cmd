@echo off
:: sort.cmd - Unix-style sort for Windows
:: Usage: sort [OPTION]... [FILE]...
:: Options:
::   -r, --reverse        Reverse the result of comparisons
::   -u, --unique         Output only unique lines
::   -n, --numeric-sort   Compare according to string numerical value
::   -h, --help           Display this help and exit

setlocal enabledelayedexpansion

set "reverse=0"
set "unique=0"
set "numeric=0"
set "files="
set "file_count=0"

:: Get the entire command line
set "cmdline=%*"

:: Check for help
echo.%cmdline% | findstr /i "\-h \-\-help" >nul
if not errorlevel 1 goto :show_help

:: Parse options
:parse_args
if "%~1"=="" goto :check_args

if /i "%~1"=="-r" (
    set "reverse=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--reverse" (
    set "reverse=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-u" (
    set "unique=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--unique" (
    set "unique=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-n" (
    set "numeric=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--numeric-sort" (
    set "numeric=1"
    shift
    goto :parse_args
)

:: Not an option, add to files
if not defined files (
    set "files=%~1"
) else (
    set "files=!files!|%~1"
)
set /a file_count+=1
shift
goto :parse_args

:check_args
:: If no files specified, read from stdin (not supported, show error)
if %file_count%==0 (
    echo Error: reading from stdin not supported in this implementation
    echo Try 'sort --help' for more information.
    exit /b 1
)

:: Create temp file for combined input
set "temp_input=%TEMP%\sort_input_%RANDOM%.txt"
set "temp_output=%TEMP%\sort_output_%RANDOM%.txt"

:: Combine all files
type nul > "%temp_input%"
for %%f in ("%files:|=" "%") do (
    if not exist "%%~f" (
        echo sort: cannot read: '%%~f': No such file or directory
        del "%temp_input%" 2>nul
        exit /b 1
    )
    if exist "%%~f\" (
        echo sort: read failed: '%%~f': Is a directory
        del "%temp_input%" 2>nul
        exit /b 1
    )
    type "%%~f" >> "%temp_input%"
)

:: Build sort command
set "sort_cmd=sort"
if %reverse%==1 set "sort_cmd=!sort_cmd! /R"

:: Sort the file
!sort_cmd! "%temp_input%" > "%temp_output%"

:: Handle unique flag
if %unique%==1 (
    set "prev_line="
    for /f "usebackq delims=" %%L in ("%temp_output%") do (
        set "line=%%L"
        if not "!line!"=="!prev_line!" (
            echo %%L
            set "prev_line=%%L"
        )
    )
) else (
    type "%temp_output%"
)

:: Cleanup
del "%temp_input%" 2>nul
del "%temp_output%" 2>nul

endlocal
exit /b 0

:show_help
echo Usage: sort [OPTION]... [FILE]...
echo Write sorted concatenation of all FILE(s) to standard output.
echo.
echo Options:
echo   -r, --reverse        Reverse the result of comparisons
echo   -u, --unique         Output only unique lines
echo   -n, --numeric-sort   Compare according to numerical value (not implemented)
echo   -h, --help           Display this help and exit
echo.
echo Note: This Windows implementation uses the native 'sort' command.
echo Numeric sorting is not fully supported in this version.
echo.
echo Examples:
echo   sort file1               Sort file1 alphabetically
echo   sort -r file1            Sort file1 in reverse order
echo   sort -u file1            Sort file1 and remove duplicates
echo   sort file1 file2         Sort combined contents of file1 and file2
exit /b 0
