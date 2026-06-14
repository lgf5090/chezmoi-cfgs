@echo off
:: rm.cmd - Unix-style file/directory removal for Windows
:: Usage: rm [OPTION]... FILE...
:: Options:
::   -f, --force          Ignore nonexistent files, never prompt
::   -r, -R, --recursive  Remove directories and their contents recursively
::   -v, --verbose        Explain what is being done
::   -i, --interactive    Prompt before every removal
::   -h, --help           Display this help and exit

setlocal enabledelayedexpansion

set "force=0"
set "recursive=0"
set "verbose=0"
set "interactive=0"
set "files="
set "file_count=0"

:: Parse arguments
:parse_args
if "%~1"=="" goto :check_args

:: Check for options
if "%~1"=="-f" (
    set "force=1"
    shift
    goto :parse_args
)
if "%~1"=="--force" (
    set "force=1"
    shift
    goto :parse_args
)
if "%~1"=="-r" (
    set "recursive=1"
    shift
    goto :parse_args
)
if "%~1"=="-R" (
    set "recursive=1"
    shift
    goto :parse_args
)
if "%~1"=="--recursive" (
    set "recursive=1"
    shift
    goto :parse_args
)
if "%~1"=="-v" (
    set "verbose=1"
    shift
    goto :parse_args
)
if "%~1"=="--verbose" (
    set "verbose=1"
    shift
    goto :parse_args
)
if "%~1"=="-i" (
    set "interactive=1"
    shift
    goto :parse_args
)
if "%~1"=="--interactive" (
    set "interactive=1"
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

:: Combined short options (e.g., -rf, -rfv)
if "%~1"=="-rf" (
    set "recursive=1"
    set "force=1"
    shift
    goto :parse_args
)
if "%~1"=="-fr" (
    set "recursive=1"
    set "force=1"
    shift
    goto :parse_args
)
if "%~1"=="-rfv" (
    set "recursive=1"
    set "force=1"
    set "verbose=1"
    shift
    goto :parse_args
)
if "%~1"=="-rv" (
    set "recursive=1"
    set "verbose=1"
    shift
    goto :parse_args
)
if "%~1"=="-fv" (
    set "force=1"
    set "verbose=1"
    shift
    goto :parse_args
)

:: Not an option, must be a file/pattern - store with delimiter
if not defined files (
    set "files=%~1"
) else (
    set "files=!files!|%~1"
)
set /a file_count+=1
shift
goto :parse_args

:check_args
:: Check if we have files to remove
if %file_count%==0 (
    if %force%==0 (
        echo Error: missing operand
        echo Try 'rm --help' for more information.
        exit /b 1
    )
    :: -f with no files is not an error, just exit
    exit /b 0
)

if %file_count%==1 if %force%==0 if %recursive%==0 if %verbose%==0 if %interactive%==0 (
    set "single_target=%files%"
    echo.!single_target! | findstr /r "[*?]" >nul 2>nul
    if errorlevel 1 if exist "!single_target!" if not exist "!single_target!\" goto :fast_remove_regular_file
)

:: Process each file pattern - expand wildcards for each pattern
:: Split by pipe delimiter and process each pattern
set "remaining=%files%"
:process_loop
if not defined remaining goto :done_processing
if "!remaining!"=="" goto :done_processing

:: Extract next pattern
for /f "tokens=1* delims=|" %%a in ("!remaining!") do (
    set "pattern=%%a"
    set "remaining=%%b"
)

:: Skip if pattern is empty
if not defined pattern goto :process_next
if "!pattern!"=="" goto :process_next

set "found=0"

:: Check if pattern contains wildcards
echo.!pattern! | findstr /r "[*?]" >nul 2>nul
if not errorlevel 1 (
    :: Has wildcards - use dir to expand
    :: Match files first
    for /f "delims=" %%f in ('dir /b /a-d "!pattern!" 2^>nul') do (
        call :remove_file "%%f"
        set "found=1"
    )
    :: Match directories
    for /f "delims=" %%d in ('dir /b /ad "!pattern!" 2^>nul') do (
        call :remove_file "%%d"
        set "found=1"
    )

    :: If nothing matched, show error
    if !found!==0 (
        if %force%==0 (
            echo Error: cannot remove '!pattern!': No such file or directory
        )
    )
) else (
    :: No wildcards - direct removal
    call :remove_file "!pattern!"
)

:process_next
goto :process_loop

:done_processing

endlocal
exit /b 0

:fast_remove_regular_file
del /f /q "%single_target%" >nul 2>nul
if errorlevel 1 (
    echo Error: cannot remove '%single_target%': Permission denied
    exit /b 1
)
endlocal
exit /b 0

:: Function to remove a file or directory
:remove_file
set "target=%~1"

:: Check if target exists (including broken symlinks)
dir /a "%target%" >nul 2>nul
if errorlevel 1 (
    :: File doesn't exist
    if %force%==0 (
        echo Error: cannot remove '%target%': No such file or directory
        exit /b 1
    )
    :: With -f, silently ignore
    exit /b 0
)

:: Interactive prompt
if %interactive%==1 (
    set /p "confirm=rm: remove '%target%'? (y/n) "
    if /i not "!confirm!"=="y" (
        if %verbose%==1 echo Skipped '%target%'
        exit /b 0
    )
)

:: Detect file type using dir with /AL (show reparse points)
set "is_symlink=0"
set "is_junction=0"
set "is_directory=0"

:: Check if it's a symlink (file or directory)
dir /al "%target%" 2>nul | find "<SYMLINK>" >nul 2>nul
if not errorlevel 1 set "is_symlink=1"

dir /al "%target%" 2>nul | find "<SYMLINKD>" >nul 2>nul
if not errorlevel 1 (
    set "is_symlink=1"
    set "is_directory=1"
)

:: Check if it's a junction
dir /al "%target%" 2>nul | find "<JUNCTION>" >nul 2>nul
if not errorlevel 1 (
    set "is_junction=1"
    set "is_directory=1"
)

:: Check if it's a regular directory (not symlink/junction)
if !is_symlink!==0 if !is_junction!==0 (
    dir /ad "%target%" >nul 2>nul
    if not errorlevel 1 set "is_directory=1"
)

:: Remove based on type
if !is_symlink!==1 goto :remove_symlink
if !is_junction!==1 goto :remove_junction
if !is_directory!==1 goto :remove_directory
goto :remove_file

:remove_symlink
:: Safe removal of symlink - only removes the link, not the target
:: IMPORTANT: Never use /s flag for symlinks, only remove the link itself
if %verbose%==1 echo Removing symlink '%target%'
:: Use rmdir for directory symlinks, del for file symlinks
if !is_directory!==1 (
    rmdir "%target%" >nul 2>nul
) else (
    del /f /q "%target%" >nul 2>nul
)
if errorlevel 1 (
    if %force%==0 (
        echo Error: cannot remove '%target%': Permission denied
        exit /b 1
    )
)
exit /b 0

:remove_junction
:: Safe removal of junction - only removes the junction, not the target
:: IMPORTANT: Never use /s flag for junctions, only remove the junction itself
if %verbose%==1 echo Removing junction '%target%'
rmdir "%target%" >nul 2>nul
if errorlevel 1 (
    if %force%==0 (
        echo Error: cannot remove '%target%': Permission denied
        exit /b 1
    )
)
exit /b 0

:remove_directory
:: Regular directory removal (not symlink/junction)
if %recursive%==0 (
    :: Without -r flag, only remove empty directory
    if %verbose%==1 echo Removing empty directory '%target%'
    rmdir "%target%" >nul 2>nul
    if errorlevel 1 (
        if %force%==0 (
            echo Error: cannot remove '%target%': Directory not empty
            echo Use -r option to remove directories recursively
            exit /b 1
        )
    )
) else (
    :: With -r flag, recursive removal of regular directory
    if %verbose%==1 echo Removing directory recursively '%target%'
    rd /s /q "%target%" >nul 2>nul
    if errorlevel 1 (
        if %force%==0 (
            echo Error: cannot remove '%target%': Permission denied
            exit /b 1
        )
    )
)
exit /b 0

:remove_file
:: Regular file removal
if %verbose%==1 echo Removing file '%target%'
del /f /q "%target%" >nul 2>nul
if errorlevel 1 (
    if %force%==0 (
        echo Error: cannot remove '%target%': Permission denied
        exit /b 1
    )
)
exit /b 0

:show_help
echo Usage: rm [OPTION]... FILE...
echo Remove (unlink) the FILE(s).
echo.
echo Options:
echo   -f, --force          Ignore nonexistent files, never prompt
echo   -r, -R, --recursive  Remove directories and their contents recursively
echo   -v, --verbose        Explain what is being done
echo   -i, --interactive    Prompt before every removal
echo   -h, --help           Display this help and exit
echo.
echo Combined short options are supported:
echo   -rf, -rfv, -rv, -fv
echo.
echo IMPORTANT SAFETY FEATURES:
echo   - Symlinks and junctions are removed safely without deleting target content
echo   - Directory symlinks use rmdir (removes link only)
echo   - File symlinks use del (removes link only)
echo   - Junctions use rmdir (removes junction only)
echo   - Regular directories require -r option for recursive removal
echo.
echo Examples:
echo   rm file.txt                Remove a file
echo   rm -f file.txt             Force remove (ignore if not exists)
echo   rm -r directory            Remove directory and contents
echo   rm -rf directory           Force remove directory recursively
echo   rm -v file.txt             Remove with verbose output
echo   rm symlink                 Remove symlink (target is safe)
exit /b 0
