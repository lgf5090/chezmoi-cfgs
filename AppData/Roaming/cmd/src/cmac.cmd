@echo off
:: cmac - Chezmoi Apply Change
:: Apply chezmoi changes for files shown in git status

setlocal enabledelayedexpansion

set "dry_run=0"
set "show_help=0"

:: Parse arguments
:parse_args
if "%~1"=="" goto :check_help
if /i "%~1"=="-d" (
    set "dry_run=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--dry-run" (
    set "dry_run=1"
    shift
    goto :parse_args
)
if /i "%~1"=="-h" (
    set "show_help=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--help" (
    set "show_help=1"
    shift
    goto :parse_args
)
echo Error: Unknown option '%~1'
set "show_help=1"
goto :check_help

:check_help
if "%show_help%"=="1" (
    echo Usage: cmac [OPTIONS]
    echo.
    echo Chezmoi Apply Change - Apply chezmoi changes for files shown in git status
    echo.
    echo OPTIONS:
    echo     -d, --dry-run    Preview what would be applied without actually applying
    echo     -h, --help       Show this help message
    echo.
    echo EXAMPLES:
    echo     cmac             Apply all changed files from git status
    echo     cmac -d          Preview changes without applying them
    echo     cmac --dry-run   Same as -d
    echo.
    echo DESCRIPTION:
    echo     Runs 'git status --short' to find changed files in chezmoi source directory,
    echo     then applies them using 'chezmoi apply' with the corresponding target path.
    echo.
    echo     Before applying, checks if files actually have changes using 'chezmoi diff'.
    echo     This prevents unnecessary applications when files haven't really changed.
    echo.
    echo     Supports all git status types: M ^(modified^), A ^(added^), R ^(renamed^),
    echo     ?? ^(untracked^), etc. Skips deleted files ^(D^).
    exit /b 0
)

:: Get git status output
git status --short >nul 2>&1
if errorlevel 1 (
    echo No changes detected in git status
    exit /b 0
)

:: Create temporary file for git status output
set "temp_git_status=%TEMP%\cmac_git_status_%RANDOM%.txt"
git status --short >"%temp_git_status%" 2>nul

:: Check if file is empty
for %%F in ("%temp_git_status%") do set "file_size=%%~zF"
if "%file_size%"=="0" (
    del "%temp_git_status%" >nul 2>&1
    echo No changes detected in git status
    exit /b 0
)

:: Count changed files
set "file_count=0"
for /f "delims=" %%L in ('type "%temp_git_status%"') do set /a file_count+=1

if "%file_count%"=="0" (
    del "%temp_git_status%" >nul 2>&1
    echo No changed files found
    exit /b 0
)

:: Display header
echo Found %file_count% changed file^(s^):
if "%dry_run%"=="1" echo [DRY RUN MODE - No changes will be applied]
echo.

:: First pass: Display changed files
for /f "tokens=1,* delims= " %%A in ('type "%temp_git_status%"') do call :display_file "%%A" "%%B"
echo.

:: Second pass: Apply each changed file
for /f "tokens=1,* delims= " %%A in ('type "%temp_git_status%"') do call :process_file "%%A" "%%B"

:: Clean up
del "%temp_git_status%" >nul 2>&1

endlocal
exit /b 0

:: Subroutine: Display a single file
:display_file
setlocal enabledelayedexpansion
set "status=%~1"
set "filepath=%~2"

:: For renamed files, extract the new filename
echo %filepath% | find " -> " >nul
if not errorlevel 1 for /f "tokens=2 delims=>" %%X in ("%filepath%") do set "filepath=%%X" & set "filepath=!filepath:~1!"

:: Display file with status indicator
echo   [%status%] !filepath!
endlocal
exit /b 0

:: Subroutine: Process a single file
:process_file
setlocal enabledelayedexpansion
set "status=%~1"
set "filepath=%~2"

:: For renamed files, extract the new filename
echo %filepath% | find " -> " >nul
if not errorlevel 1 for /f "tokens=2 delims=>" %%X in ("%filepath%") do set "filepath=%%X" & set "filepath=!filepath:~1!"

:: Skip deleted files
echo %status% | find "D" >nul
if not errorlevel 1 (
    echo Skipping deleted file: !filepath!
    echo.
    endlocal
    exit /b 0
)

:: Convert chezmoi source path to target path
set "target_path=!filepath!"
set "target_path=!target_path:dot_=.!"
set "target_path=!target_path:private_=!"
set "target_path=!target_path:executable_=!"
set "target_path=!target_path:/=\!"

:: Construct full target path
set "full_path=%USERPROFILE%\!target_path!"

:: Dry run mode - just preview
if "%dry_run%"=="1" (
    echo [DRY RUN] Would apply [%status%]: !filepath! -^> !full_path!
    endlocal
    exit /b 0
)

:: Check if file actually has changes using chezmoi diff
set "temp_diff=%TEMP%\cmac_diff_%RANDOM%.txt"
chezmoi diff "!full_path!" >"%temp_diff%" 2>&1

:: Check if diff is empty
set "diff_size=0"
for %%F in ("%temp_diff%") do set "diff_size=%%~zF"
del "%temp_diff%" >nul 2>&1

if "!diff_size!"=="0" (
    echo Skipping ^(no changes^): !filepath!
    echo.
    endlocal
    exit /b 0
)

:: Actually apply the change
echo Applying [%status%]: !filepath! -^> !full_path!

chezmoi apply "!full_path!" >nul 2>&1
set "apply_exit=!errorlevel!"
if "!apply_exit!" neq "0" (
    echo   X Failed ^(exit code: !apply_exit!^)
) else (
    echo   + Success
)
echo.

endlocal
exit /b 0
