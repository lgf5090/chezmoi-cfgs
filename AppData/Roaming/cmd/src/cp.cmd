@echo off
:: cp.cmd - Unix-style copy for Windows
:: Usage: cp [OPTION]... SOURCE... DEST
:: Options:
::   -r, -R, --recursive  Copy directories recursively
::   -v, --verbose        Explain what is being done
::   -f, --force          Do not prompt before overwriting
::   -i, --interactive    Prompt before overwrite
::   -n, --no-clobber     Do not overwrite an existing file
::   -h, --help           Display this help and exit

setlocal enabledelayedexpansion

set "verbose=0"
set "force=0"
set "interactive=0"
set "no_clobber=0"
set "recursive=0"
set "args="

:: Get the entire command line and remove the script name
set "cmdline=%*"

:: Check for help
echo.%cmdline% | findstr /i "\-h \-\-help" >nul
if not errorlevel 1 goto :show_help

if not "%~1"=="" if not "%~2"=="" if "%~3"=="" (
    set "first_arg=%~1"
    if not "!first_arg:~0,1!"=="-" goto :fast_copy_file
)

:: Parse options
:parse_args
if "%~1"=="" goto :check_args

if /i "%~1"=="-v" (
    set "verbose=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--verbose" (
    set "verbose=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-f" (
    set "force=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--force" (
    set "force=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-i" (
    set "interactive=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--interactive" (
    set "interactive=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-n" (
    set "no_clobber=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--no-clobber" (
    set "no_clobber=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-r" (
    set "recursive=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-R" (
    set "recursive=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--recursive" (
    set "recursive=1"
    shift
    goto :parse_args
)

:: Not an option, add to args
if not defined args (
    set "args=%~1"
) else (
    set "args=!args!|%~1"
)
shift
goto :parse_args

:check_args
:: Check if we have at least source and destination
if not defined args (
    echo Error: missing file operand
    echo Try 'cp --help' for more information.
    exit /b 1
)

:: Count arguments
set "arg_count=0"
for %%a in ("%args:|=" "%") do set /a arg_count+=1

if %arg_count% LSS 2 (
    echo Error: missing destination file operand
    echo Try 'cp --help' for more information.
    exit /b 1
)

:: Split args into sources and dest
set "sources="
set "dest="
set "current=0"

for %%a in ("%args:|=" "%") do (
    set /a current+=1
    if !current! EQU %arg_count% (
        set "dest=%%~a"
    ) else (
        if not defined sources (
            set "sources=%%~a"
        ) else (
            set "sources=!sources!|%%~a"
        )
    )
)

:: Check if destination is a directory
set "dest_is_dir=0"
if exist "%dest%\" set "dest_is_dir=1"

:: If multiple sources, destination must be a directory
if %arg_count% GTR 2 (
    if %dest_is_dir%==0 (
        echo Error: target '%dest%' is not a directory
        exit /b 1
    )
)

:: Process each source
for %%s in ("%sources:|=" "%") do (
    call :copy_item "%%~s" "%dest%" %dest_is_dir%
    if errorlevel 1 exit /b 1
)

endlocal
exit /b 0

:fast_copy_file
set "source=%~1"
set "destination=%~2"
if not exist "%source%" (
    echo Error: cannot stat '%source%': No such file or directory
    exit /b 1
)
if exist "%source%\" (
    echo Error: -r not specified; omitting directory '%source%'
    exit /b 1
)
set "final_dest=%destination%"
if exist "%destination%\" (
    for %%f in ("%source%") do set "final_dest=%destination%\%%~nxf"
)
copy /Y "%source%" "%final_dest%" >nul 2>nul
if errorlevel 1 (
    echo Error: cannot copy '%source%' to '%final_dest%'
    exit /b 1
)
endlocal
exit /b 0

:: Function to copy a file or directory
:copy_item
set "source=%~1"
set "destination=%~2"
set "dest_is_dir=%~3"

:: Check if source exists
if not exist "%source%" (
    echo Error: cannot stat '%source%': No such file or directory
    exit /b 1
)

:: Check if source is a directory
set "source_is_dir=0"
if exist "%source%\" set "source_is_dir=1"

:: If source is a directory, check if recursive flag is set
if %source_is_dir%==1 (
    if %recursive%==0 (
        echo Error: -r not specified; omitting directory '%source%'
        exit /b 1
    )
)

:: Determine final destination path
set "final_dest=%destination%"
if %dest_is_dir%==1 (
    for %%f in ("%source%") do set "final_dest=%destination%\%%~nxf"
)

:: Check if destination exists
if exist "%final_dest%" (
    if %no_clobber%==1 (
        if %verbose%==1 echo Skipping '%source%': destination exists
        exit /b 0
    )

    if %interactive%==1 (
        set /p "confirm=cp: overwrite '%final_dest%'? (y/n) "
        if /i not "!confirm!"=="y" (
            if %verbose%==1 echo Skipping '%source%'
            exit /b 0
        )
    )
)

:: Perform the copy
if %verbose%==1 echo '%source%' -> '%final_dest%'

if %source_is_dir%==1 (
    :: Copy directory recursively
    xcopy /E /I /Y /Q "%source%" "%final_dest%" >nul 2>nul
) else (
    :: Copy file
    copy /Y "%source%" "%final_dest%" >nul 2>nul
)

if errorlevel 1 (
    echo Error: cannot copy '%source%' to '%final_dest%'
    exit /b 1
)

exit /b 0

:show_help
echo Usage: cp [OPTION]... SOURCE... DEST
echo Copy SOURCE to DEST, or multiple SOURCE(s) to DEST directory.
echo.
echo Options:
echo   -r, -R, --recursive  Copy directories recursively
echo   -v, --verbose        Explain what is being done
echo   -f, --force          Do not prompt before overwriting
echo   -i, --interactive    Prompt before overwrite
echo   -n, --no-clobber     Do not overwrite an existing file
echo   -h, --help           Display this help and exit
echo.
echo Examples:
echo   cp file1 file2              Copy file1 to file2
echo   cp file1 file2 dir/         Copy file1 and file2 to dir/
echo   cp -r dir1 dir2             Copy directory dir1 to dir2 recursively
echo   cp -i file1 file2           Prompt before overwriting file2
echo   cp -v *.txt backup/         Copy all .txt files to backup/ with verbose output
exit /b 0
