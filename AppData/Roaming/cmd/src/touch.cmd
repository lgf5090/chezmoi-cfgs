@echo off
:: touch.cmd - Unix-style file creation for Windows with brace expansion
:: Usage: touch [OPTION]... FILE...
:: Options:
::   -v, --verbose        Explain what is being done
::   -h, --help           Display this help and exit
:: Supports brace expansion: touch test/{a,b,c}.txt creates test/a.txt, test/b.txt, test/c.txt

setlocal enabledelayedexpansion

set "verbose=0"
set "files="
set "file_count=0"

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

if %verbose%==0 if not "%~1"=="" if "%~2"=="" (
    set "first_arg=%~1"
    if not "!first_arg:~0,1!"=="-" if "!first_arg!"=="!first_arg:{=!" goto :fast_touch_file
)

:: Trim spaces
for /f "tokens=*" %%a in ("!cmdline!") do set "cmdline=%%a"

:: Check if command line contains braces for expansion
echo.!cmdline! | findstr /r "{.*}" >nul 2>nul
if not errorlevel 1 (
    call :expand_braces "!cmdline!"
) else (
    set "files=!cmdline!"
    set "file_count=1"
)

:check_args
:: Check if we have files to create
if %file_count%==0 (
    echo Error: missing file operand
    echo Try 'touch --help' for more information.
    exit /b 1
)

:: Process each file
for %%f in ("%files:|=" "%") do (
    call :touch_file "%%~f"
)

endlocal
exit /b 0

:fast_touch_file
set "target=%first_arg%"
for %%D in ("%target%") do set "target_dir=%%~dpD"
if defined target_dir if not exist "%target_dir%" (
    mkdir "%target_dir%" >nul 2>nul
    if errorlevel 1 (
        echo Error: cannot create directory '%target_dir%': Permission denied or invalid path
        exit /b 1
    )
)
if exist "%target%" (
    copy /b "%target%"+,, "%target%" >nul 2>nul
) else (
    type nul > "%target%" 2>nul
)
if errorlevel 1 (
    echo Error: cannot create file '%target%': Permission denied or invalid path
    exit /b 1
)
endlocal
exit /b 0

:: Function to expand braces like test/{a,b,c}.txt
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

:: Reset files and file_count since we're expanding
set "files="
set "file_count=0"

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
    if not defined files (
        set "files=!expanded!"
    ) else (
        set "files=!files!|!expanded!"
    )
    set /a file_count+=1
)

exit /b 0

:: Function to create/update a file (like Unix touch)
:touch_file
set "target=%~1"

:: Skip empty targets
if not defined target exit /b 0
if "%target%"=="" exit /b 0

:: Get the directory path
set "target_dir=%~dp1"

:: Create parent directory if it doesn't exist
if not "%target_dir%"=="" (
    if not exist "%target_dir%" (
        if %verbose%==1 echo Creating directory: '%target_dir%'
        mkdir "%target_dir%" >nul 2>nul
        if errorlevel 1 (
            echo Error: cannot create directory '%target_dir%': Permission denied or invalid path
            exit /b 1
        )
    )
)

:: Check if file already exists
if exist "%target%" (
    if %verbose%==1 echo Updating timestamp: '%target%'
    :: Update timestamp by copying to temp and back
    copy /b "%target%"+,, "%target%" >nul 2>nul
    if errorlevel 1 (
        echo Error: cannot update timestamp for '%target%'
        exit /b 1
    )
) else (
    :: Create new file
    if %verbose%==1 echo Creating file: '%target%'
    type nul > "%target%" 2>nul
    if errorlevel 1 (
        echo Error: cannot create file '%target%': Permission denied or invalid path
        exit /b 1
    )
)

exit /b 0

:show_help
echo Usage: touch [OPTION]... FILE...
echo Create files or update timestamps.
echo.
echo Options:
echo   -v, --verbose        Explain what is being done
echo   -h, --help           Display this help and exit
echo.
echo This command creates parent directories as needed (like mkdir -p).
echo If a file exists, its timestamp is updated.
echo.
echo Brace expansion is supported:
echo   touch test/{a,b,c}.txt    Creates test/a.txt, test/b.txt, test/c.txt
echo.
echo Examples:
echo   touch myfile.txt            Create a file
echo   touch path/to/file.txt      Create file with parent directories
echo   touch -v test/{1,2,3}.log   Create multiple files with verbose output
exit /b 0
