@echo off
:: head.cmd - Unix-style head for Windows
:: Usage: head [OPTION]... [FILE]...
:: Options:
::   -n, --lines=NUM      Print first NUM lines (default: 10)
::   -h, --help           Display this help and exit

setlocal enabledelayedexpansion

set "num_lines=10"
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

:: Check for -n with value
if /i "%~1"=="-n" (
    if "%~2"=="" (
        echo Error: option requires an argument -- 'n'
        exit /b 1
    )
    :: Remove any quotes and spaces
    set "num_lines=%~2"
    set "num_lines=!num_lines: =!"
    shift
    shift
    goto :parse_args
)

:: Check for --lines=NUM format
set "arg=%~1"
echo !arg! | findstr /b /i "\-\-lines=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%a in ("!arg!") do set "num_lines=%%a"
    shift
    goto :parse_args
)

:: Check for -NUM format (like -5)
set "arg=%~1"
if "!arg:~0,1!"=="-" (
    set "potential_num=!arg:~1!"
    set "is_num=1"
    for /f "delims=0123456789" %%i in ("!potential_num!") do set "is_num="
    if defined is_num if not "!potential_num!"=="" (
        set "num_lines=!potential_num!"
        shift
        goto :parse_args
    )
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
:: Clean and validate num_lines is a number
set "num_lines=%num_lines: =%"
set "is_numeric=1"
for /f "delims=0123456789" %%i in ("!num_lines!") do set "is_numeric="
if not defined is_numeric (
    echo Error: invalid number of lines: '%num_lines%'
    exit /b 1
)
if "!num_lines!"=="" (
    echo Error: invalid number of lines: ''
    exit /b 1
)

:: If no files specified, read from stdin (not supported, show error)
if %file_count%==0 (
    echo Error: reading from stdin not supported in this implementation
    echo Try 'head --help' for more information.
    exit /b 1
)

:: Process each file
set "show_headers=0"
if %file_count% GTR 1 set "show_headers=1"

set "first_file=1"
for %%f in ("%files:|=" "%") do (
    if !show_headers!==1 (
        if !first_file!==0 echo.
        echo ==^> %%~f ^<==
        set "first_file=0"
    )
    call :head_file "%%~f" %num_lines%
    if errorlevel 1 exit /b 1
)

endlocal
exit /b 0

:: Function to output first N lines of a file
:head_file
set "filepath=%~1"
set "lines=%~2"

:: Check if file exists
if not exist "%filepath%" (
    echo head: cannot open '%filepath%' for reading: No such file or directory
    exit /b 1
)

:: Check if it's a directory
if exist "%filepath%\" (
    echo head: error reading '%filepath%': Is a directory
    exit /b 1
)

:: Read and output first N lines
if %lines% LEQ 0 exit /b 0
set "count=0"
for /f "usebackq delims=" %%L in ("%filepath%") do (
    if !count! LSS %lines% (
        echo %%L
        set /a count+=1
        if !count! GEQ %lines% goto :head_done
    )
)

:head_done
exit /b 0

:show_help
echo Usage: head [OPTION]... [FILE]...
echo Print the first 10 lines of each FILE to standard output.
echo With more than one FILE, precede each with a header giving the file name.
echo.
echo Options:
echo   -n, --lines=NUM      Print first NUM lines instead of first 10
echo   -NUM                 Same as --lines=NUM
echo   -h, --help           Display this help and exit
echo.
echo Examples:
echo   head file1               Display first 10 lines of file1
echo   head -n 20 file1         Display first 20 lines of file1
echo   head -5 file1            Display first 5 lines of file1
echo   head file1 file2         Display first 10 lines of file1 and file2
exit /b 0
