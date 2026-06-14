@echo off
:: cat.cmd - Unix-style file concatenation for Windows
:: Usage: cat [OPTION]... [FILE]...
:: Options:
::   -n, --number         Number all output lines
::   -b, --number-nonblank Number nonempty output lines, overrides -n
::   -s, --squeeze-blank  Suppress repeated empty output lines
::   -h, --help           Display this help and exit

setlocal enabledelayedexpansion

set "number_lines=0"
set "number_nonblank=0"
set "squeeze_blank=0"
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

if /i "%~1"=="-n" (
    set "number_lines=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--number" (
    set "number_lines=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-b" (
    set "number_nonblank=1"
    set "number_lines=0"
    shift
    goto :parse_args
)
if /i "%~1"=="--number-nonblank" (
    set "number_nonblank=1"
    set "number_lines=0"
    shift
    goto :parse_args
)
if /i "%~1"=="-s" (
    set "squeeze_blank=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--squeeze-blank" (
    set "squeeze_blank=1"
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
:: If no files specified, read from stdin (not supported in batch, show error)
if %file_count%==0 (
    echo Error: reading from stdin not supported in this implementation
    echo Try 'cat --help' for more information.
    exit /b 1
)

:: Process each file
set "line_num=0"
set "prev_blank=0"

for %%f in ("%files:|=" "%") do (
    call :cat_file "%%~f"
    if errorlevel 1 exit /b 1
)

endlocal
exit /b 0

:: Function to output a file
:cat_file
set "filepath=%~1"

:: Check if file exists
if not exist "%filepath%" (
    echo cat: %filepath%: No such file or directory
    exit /b 1
)

:: Check if it's a directory
if exist "%filepath%\" (
    echo cat: %filepath%: Is a directory
    exit /b 1
)

:: Fast path for plain concatenation.
if %number_lines%==0 if %number_nonblank%==0 if %squeeze_blank%==0 (
    type "%filepath%"
    exit /b %errorlevel%
)

:: Read and output file
for /f "usebackq delims=" %%L in ("%filepath%") do (
    call :output_line "%%L"
)

:: Handle last line if file doesn't end with newline
if %number_lines%==1 (
    set /a line_num+=1
)

exit /b 0

:: Function to output a single line
:output_line
set "line=%~1"

:: Check if line is blank
set "is_blank=0"
if "!line!"=="" set "is_blank=1"

:: Squeeze blank lines if needed
if %squeeze_blank%==1 (
    if !is_blank!==1 (
        if !prev_blank!==1 (
            exit /b 0
        )
        set "prev_blank=1"
    ) else (
        set "prev_blank=0"
    )
)

:: Number lines
if %number_nonblank%==1 (
    if !is_blank!==0 (
        set /a line_num+=1
        echo    !line_num!  !line!
    ) else (
        echo.
    )
) else if %number_lines%==1 (
    set /a line_num+=1
    echo    !line_num!  !line!
) else (
    echo !line!
)

exit /b 0

:show_help
echo Usage: cat [OPTION]... [FILE]...
echo Concatenate FILE(s) to standard output.
echo.
echo Options:
echo   -n, --number         Number all output lines
echo   -b, --number-nonblank Number nonempty output lines, overrides -n
echo   -s, --squeeze-blank  Suppress repeated empty output lines
echo   -h, --help           Display this help and exit
echo.
echo Examples:
echo   cat file1               Display contents of file1
echo   cat file1 file2         Concatenate and display file1 and file2
echo   cat -n file1            Display file1 with line numbers
echo   cat -b file1            Display file1 with numbered non-blank lines
exit /b 0
