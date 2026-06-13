@echo off
:: wc.cmd - Unix-style word count for Windows
:: Usage: wc [OPTION]... [FILE]...
:: Options:
::   -l, --lines          Print the newline counts
::   -w, --words          Print the word counts
::   -c, --bytes          Print the byte counts
::   -m, --chars          Print the character counts
::   -L, --max-line-length Print the length of the longest line
::   -h, --help           Display this help and exit

setlocal enabledelayedexpansion

set "count_lines=0"
set "count_words=0"
set "count_bytes=0"
set "count_chars=0"
set "max_length=0"
set "show_all=1"
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

if /i "%~1"=="-l" (
    set "count_lines=1"
    set "show_all=0"
    shift
    goto :parse_args
)
if /i "%~1"=="--lines" (
    set "count_lines=1"
    set "show_all=0"
    shift
    goto :parse_args
)
if /i "%~1"=="-w" (
    set "count_words=1"
    set "show_all=0"
    shift
    goto :parse_args
)
if /i "%~1"=="--words" (
    set "count_words=1"
    set "show_all=0"
    shift
    goto :parse_args
)
if /i "%~1"=="-c" (
    set "count_bytes=1"
    set "show_all=0"
    shift
    goto :parse_args
)
if /i "%~1"=="--bytes" (
    set "count_bytes=1"
    set "show_all=0"
    shift
    goto :parse_args
)
if /i "%~1"=="-m" (
    set "count_chars=1"
    set "show_all=0"
    shift
    goto :parse_args
)
if /i "%~1"=="--chars" (
    set "count_chars=1"
    set "show_all=0"
    shift
    goto :parse_args
)
if /i "%~1"=="-L" (
    set "max_length=1"
    set "show_all=0"
    shift
    goto :parse_args
)
if /i "%~1"=="--max-line-length" (
    set "max_length=1"
    set "show_all=0"
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
    echo Try 'wc --help' for more information.
    exit /b 1
)

:: If show_all, enable all counts
if %show_all%==1 (
    set "count_lines=1"
    set "count_words=1"
    set "count_bytes=1"
)

:: Initialize totals
set "total_lines=0"
set "total_words=0"
set "total_bytes=0"
set "total_max_len=0"

:: Process each file
for %%f in ("%files:|=" "%") do (
    call :count_file "%%~f"
    if errorlevel 1 exit /b 1
)

:: Show totals if multiple files
if %file_count% GTR 1 (
    call :display_counts !total_lines! !total_words! !total_bytes! !total_max_len! "total"
)

endlocal
exit /b 0

:: Function to count a file
:count_file
set "filepath=%~1"

:: Check if file exists
if not exist "%filepath%" (
    echo wc: %filepath%: No such file or directory
    exit /b 1
)

:: Check if it's a directory
if exist "%filepath%\" (
    echo wc: %filepath%: Is a directory
    exit /b 1
)

:: Count lines using find command (more accurate)
set "lines=0"
for /f "tokens=3" %%A in ('find /c /v "" "%filepath%"') do set "lines=%%A"

:: Count words and max line length
set "words=0"
set "max_len=0"

for /f "usebackq delims=" %%L in ("%filepath%") do (
    set "line=%%L"

    :: Count words in line
    if defined line (
        for %%w in (!line!) do set /a words+=1
    )

    :: Track max line length
    if defined line (
        set "len=0"
        set "temp_line=!line!"
        :count_len
        if defined temp_line (
            set "temp_line=!temp_line:~1!"
            set /a len+=1
            goto :count_len
        )
        if !len! GTR !max_len! set "max_len=!len!"
    )
)

:: Handle empty lines in word count (they are skipped by for /f)
:: The word count may be slightly inaccurate for files with only whitespace lines

:: Get file size (bytes)
for %%A in ("%filepath%") do set "bytes=%%~zA"

:: Update totals
set /a total_lines+=lines
set /a total_words+=words
set /a total_bytes+=bytes
if %max_len% GTR %total_max_len% set "total_max_len=%max_len%"

:: Display counts for this file
call :display_counts %lines% %words% %bytes% %max_len% "%filepath%"

exit /b 0

:: Function to display counts
:display_counts
set "d_lines=%~1"
set "d_words=%~2"
set "d_bytes=%~3"
set "d_maxlen=%~4"
set "d_file=%~5"

set "output="
if %count_lines%==1 set "output=!output!  %d_lines%"
if %count_words%==1 set "output=!output!  %d_words%"
if %count_bytes%==1 set "output=!output!  %d_bytes%"
if %count_chars%==1 set "output=!output!  %d_bytes%"
if %max_length%==1 set "output=!output!  %d_maxlen%"

echo !output! %d_file%

exit /b 0

:show_help
echo Usage: wc [OPTION]... [FILE]...
echo Print newline, word, and byte counts for each FILE.
echo.
echo Options:
echo   -l, --lines          Print the newline counts
echo   -w, --words          Print the word counts
echo   -c, --bytes          Print the byte counts
echo   -m, --chars          Print the character counts
echo   -L, --max-line-length Print the length of the longest line
echo   -h, --help           Display this help and exit
echo.
echo With no options, prints line, word, and byte counts.
echo.
echo Examples:
echo   wc file1                 Count lines, words, and bytes in file1
echo   wc -l file1              Count only lines in file1
echo   wc -w file1 file2        Count only words in file1 and file2
echo   wc -L file1              Show length of longest line in file1
exit /b 0
