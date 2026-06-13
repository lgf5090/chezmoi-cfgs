@echo off
:: uniq.cmd - Unix-style uniq for Windows
:: Usage: uniq [OPTION]... [INPUT]
:: Options:
::   -c, --count          Prefix lines by the number of occurrences
::   -d, --repeated       Only print duplicate lines
::   -u, --unique         Only print unique lines
::   -i, --ignore-case    Ignore differences in case when comparing
::   -h, --help           Display this help and exit

setlocal enabledelayedexpansion

set "show_count=0"
set "only_repeated=0"
set "only_unique=0"
set "ignore_case=0"
set "input_file="

:: Get the entire command line
set "cmdline=%*"

:: Check for help
echo.%cmdline% | findstr /i "\-h \-\-help" >nul
if not errorlevel 1 goto :show_help

:: Parse options
:parse_args
if "%~1"=="" goto :check_args

if /i "%~1"=="-c" (
    set "show_count=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--count" (
    set "show_count=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-d" (
    set "only_repeated=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--repeated" (
    set "only_repeated=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-u" (
    set "only_unique=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--unique" (
    set "only_unique=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-i" (
    set "ignore_case=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--ignore-case" (
    set "ignore_case=1"
    shift
    goto :parse_args
)

:: Not an option, must be input file
if not defined input_file (
    set "input_file=%~1"
    shift
    goto :parse_args
) else (
    echo Error: too many arguments
    exit /b 1
)

:check_args
:: If no input file specified, read from stdin (not supported, show error)
if not defined input_file (
    echo Error: reading from stdin not supported in this implementation
    echo Try 'uniq --help' for more information.
    exit /b 1
)

:: Check if file exists
if not exist "%input_file%" (
    echo uniq: %input_file%: No such file or directory
    exit /b 1
)

:: Check if it's a directory
if exist "%input_file%\" (
    echo uniq: %input_file%: Is a directory
    exit /b 1
)

:: Process file
set "prev_line="
set "prev_line_lower="
set "count=0"

for /f "usebackq delims=" %%L in ("%input_file%") do (
    set "line=%%L"
    set "line_lower=!line!"

    :: Convert to lowercase for comparison if ignore_case is set
    if %ignore_case%==1 (
        for %%A in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
            set "line_lower=!line_lower:%%A=%%A!"
        )
        call :to_lower line_lower
    )

    :: Check if this line is same as previous
    set "is_same=0"
    if %ignore_case%==1 (
        if "!line_lower!"=="!prev_line_lower!" set "is_same=1"
    ) else (
        if "!line!"=="!prev_line!" set "is_same=1"
    )

    :: If different line, output previous line (if any)
    if !is_same!==0 (
        if defined prev_line (
            call :output_line "!prev_line!" !count!
        )
        set "prev_line=!line!"
        set "prev_line_lower=!line_lower!"
        set "count=1"
    ) else (
        set /a count+=1
    )
)

:: Output last line
if defined prev_line (
    call :output_line "!prev_line!" !count!
)

endlocal
exit /b 0

:: Function to output a line based on options
:output_line
set "out_line=%~1"
set "out_count=%~2"

:: Check if we should output this line
set "should_output=1"

if %only_repeated%==1 (
    if %out_count% LEQ 1 set "should_output=0"
)

if %only_unique%==1 (
    if %out_count% GTR 1 set "should_output=0"
)

:: Output line if needed
if %should_output%==1 (
    if %show_count%==1 (
        echo   %out_count% %out_line%
    ) else (
        echo %out_line%
    )
)

exit /b 0

:: Function to convert string to lowercase
:to_lower
set "str=!%~1!"
for %%A in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    for %%B in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        set "str=!str:%%B=%%A!"
    )
)
set "%~1=!str!"
exit /b 0

:show_help
echo Usage: uniq [OPTION]... [INPUT]
echo Filter adjacent matching lines from INPUT, writing to standard output.
echo.
echo Options:
echo   -c, --count          Prefix lines by the number of occurrences
echo   -d, --repeated       Only print duplicate lines
echo   -u, --unique         Only print unique lines
echo   -i, --ignore-case    Ignore differences in case when comparing
echo   -h, --help           Display this help and exit
echo.
echo Note: uniq only removes duplicate adjacent lines.
echo Use 'sort file | uniq' to remove all duplicate lines.
echo.
echo Examples:
echo   uniq file1               Remove adjacent duplicate lines
echo   uniq -c file1            Show count of occurrences
echo   uniq -d file1            Show only duplicate lines
echo   uniq -u file1            Show only unique lines
echo   uniq -i file1            Ignore case when comparing
exit /b 0
