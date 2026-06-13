@echo off
:: ln.cmd - Unix-style symbolic link creation for Windows
:: Usage: ln [OPTION]... TARGET LINK_NAME
::        ln [OPTION]... TARGET... DIRECTORY
:: Options:
::   -s, --symbolic       Create symbolic links instead of hard links
::   -f, --force          Remove existing destination files
::   -n, --no-dereference Treat LINK_NAME as normal file if it's a symlink to directory
::   -v, --verbose        Print name of each linked file
::   -d, --directory      Allow creating hard links to directories (requires admin)
::   -h, --help           Display this help and exit

setlocal enabledelayedexpansion

set "symbolic=0"
set "force=0"
set "verbose=0"
set "no_dereference=0"
set "directory_link=0"
set "targets="
set "link_name="
set "target_count=0"

:: Parse arguments
:parse_args
if "%~1"=="" goto :check_args

:: Check for options
if "%~1"=="-s" (
    set "symbolic=1"
    shift
    goto :parse_args
)
if "%~1"=="--symbolic" (
    set "symbolic=1"
    shift
    goto :parse_args
)
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
if "%~1"=="-n" (
    set "no_dereference=1"
    shift
    goto :parse_args
)
if "%~1"=="--no-dereference" (
    set "no_dereference=1"
    shift
    goto :parse_args
)
if "%~1"=="-d" (
    set "directory_link=1"
    shift
    goto :parse_args
)
if "%~1"=="--directory" (
    set "directory_link=1"
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

:: Combined short options (e.g., -sf, -sfv)
if "%~1"=="-sf" (
    set "symbolic=1"
    set "force=1"
    shift
    goto :parse_args
)
if "%~1"=="-sfv" (
    set "symbolic=1"
    set "force=1"
    set "verbose=1"
    shift
    goto :parse_args
)
if "%~1"=="-sv" (
    set "symbolic=1"
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
if "%~1"=="-fs" (
    set "symbolic=1"
    set "force=1"
    shift
    goto :parse_args
)
if "%~1"=="-vs" (
    set "symbolic=1"
    set "verbose=1"
    shift
    goto :parse_args
)
if "%~1"=="-vf" (
    set "force=1"
    set "verbose=1"
    shift
    goto :parse_args
)

:: Not an option, must be target or link_name
if not defined targets (
    set "targets=%~1"
    set /a target_count+=1
) else (
    set "targets=!targets! %~1"
    set /a target_count+=1
)
shift
goto :parse_args

:check_args
:: Check if we have at least 2 arguments (target and link_name)
if %target_count% LSS 2 (
    echo Error: Missing file operand
    echo Try 'ln --help' for more information.
    exit /b 1
)

:: Extract link_name (last argument)
set "args_list=%targets%"
set "last_arg="
for %%a in (%args_list%) do (
    if defined last_arg set "all_targets=!all_targets! !last_arg!"
    set "last_arg=%%a"
)
set "link_name=%last_arg%"

:: Remove leading space from all_targets
set "all_targets=%all_targets:~1%"

:: If only one target, process single link
if %target_count% EQU 2 goto :create_single_link

:: Multiple targets - link_name must be a directory
if not exist "%link_name%\" (
    echo Error: '%link_name%' is not a directory
    exit /b 1
)

:: Create links for each target in the directory
for %%t in (%all_targets%) do (
    set "target=%%~t"
    set "target_name=%%~nxt"
    call :create_link "!target!" "%link_name%\!target_name!"
)
goto :end

:create_single_link
:: Extract the single target
for %%t in (%all_targets%) do set "target=%%~t"
call :create_link "%target%" "%link_name%"
goto :end

:: Function to create a link
:create_link
set "src=%~1"
set "dst=%~2"

:: Check if target exists
if not exist "%src%" (
    echo Error: failed to access '%src%': No such file or directory
    exit /b 1
)

:: Handle force option - remove existing destination
if %force%==1 (
    :: Check if dst exists (including broken symlinks)
    dir /a "%dst%" >nul 2>nul
    if not errorlevel 1 (
        :: File/link exists, remove it
        attrib -r -h -s "%dst%" >nul 2>nul
        :: For junctions and directory symlinks, use rmdir without /s
        rmdir "%dst%" >nul 2>nul && goto :force_delete_done
        :: For file symlinks and files, use del
        del /f /q "%dst%" >nul 2>nul && goto :force_delete_done
        :: Try fsutil (works for broken junctions)
        fsutil reparsepoint delete "%dst%" >nul 2>nul && goto :force_delete_done
        :: Last resort: try rd /s /q for real directories
        rd /s /q "%dst%" >nul 2>nul && goto :force_delete_done
        :: If we get here, deletion failed
        echo Error: failed to remove '%dst%' with -f option
        exit /b 1
    )
)
:force_delete_done

:: Check if destination already exists (including broken symlinks)
:: Refresh directory to avoid cache issues
dir "%~dp2" >nul 2>nul
dir /a "%dst%" >nul 2>nul
if not errorlevel 1 (
    echo Error: failed to create link '%dst%': File exists
    exit /b 1
)

:: Convert to absolute paths for mklink
for %%A in ("%src%") do set "src_abs=%%~fA"
for %%A in ("%dst%") do set "dst_abs=%%~fA"

:: Determine if target is a file or directory using dir with attributes
set "is_directory=0"
dir /ad "%src%" >nul 2>nul
if not errorlevel 1 set "is_directory=1"

:: Create the link based on type
if %symbolic%==1 goto :create_symlink
goto :create_hardlink

:create_symlink
if %is_directory%==1 (
    mklink /D "%dst_abs%" "%src_abs%" >nul
) else (
    mklink "%dst_abs%" "%src_abs%" >nul
)
if errorlevel 1 (
    echo Error: failed to create symbolic link '%dst%' -^> '%src%'
    exit /b 1
)
if %verbose%==1 echo '%dst%' -^> '%src%'
exit /b 0

:create_hardlink
:: Double-check destination doesn't exist before creating hard link
dir /a "%dst_abs%" >nul 2>nul
if not errorlevel 1 (
    echo Error: Destination '%dst%' already exists
    exit /b 1
)

if "%is_directory%"=="1" goto :create_junction
if "%is_directory%"=="0" goto :create_file_hardlink
echo Error: Unexpected is_directory value: %is_directory%
exit /b 1

:create_junction
if "%directory_link%"=="0" (
    echo Error: cannot create hard link '%dst%': Is a directory
    echo Use -d option to allow directory hard links
    exit /b 1
)
mklink /J "%dst_abs%" "%src_abs%" >nul
goto :check_hardlink_result

:create_file_hardlink
mklink /H "%dst_abs%" "%src_abs%" >nul
goto :check_hardlink_result

:check_hardlink_result
if errorlevel 1 (
    echo Error: failed to create hard link '%dst%' =^> '%src%'
    exit /b 1
)
if %verbose%==1 echo '%dst%' =^> '%src%'
exit /b 0

:show_help
echo Usage: ln [OPTION]... TARGET LINK_NAME
echo    or: ln [OPTION]... TARGET... DIRECTORY
echo Create links to TARGET with the name LINK_NAME.
echo By default, creates hard links; with -s, creates symbolic links.
echo.
echo Options:
echo   -s, --symbolic       Create symbolic links instead of hard links
echo   -f, --force          Remove existing destination files
echo   -n, --no-dereference Treat LINK_NAME as normal file if it's a symlink
echo   -v, --verbose        Print name of each linked file
echo   -d, --directory      Allow hard links to directories (creates junction)
echo   -h, --help           Display this help and exit
echo.
echo Combined short options are supported:
echo   -sf, -sfv, -sv, -fv, -fs, -vs, -vf
echo.
echo Examples:
echo   ln target.txt link.txt             Create a hard link
echo   ln -s target.txt link.txt          Create a symbolic link
echo   ln -sf target.txt link.txt         Force create symbolic link
echo   ln -sfv target.txt link.txt        Force create with verbose output
echo   ln -s target1 target2 dir/         Create symbolic links in directory
echo.
echo Windows Implementation Notes:
echo   Hard links:     Use mklink /H (files only, same volume)
echo   Symbolic links: Use mklink or mklink /D (may require admin/dev mode)
echo   Directory hard: Use mklink /J (junction, requires -d option)
exit /b 0

:end
endlocal
exit /b 0
