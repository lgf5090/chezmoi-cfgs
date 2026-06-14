@echo off
:: CMD startup configuration.
:: Load conf.d settings and register builtin function macros quickly.

:: Use UTF-8 code page for commands that emit Unicode output.
chcp 65001 >nul 2>&1

echo ================================
echo Loading CMD configuration...
echo ================================
echo.

:: ===========================================
:: Load configuration files from conf.d.
:: ===========================================
set "CONF_DIR=%~dp0conf.d"

if exist "%CONF_DIR%" (
    echo [config]
    for %%e in (cmd bat) do (
        for %%f in ("%CONF_DIR%\*.%%e") do (
            if exist "%%f" (
                echo   [+] %%~nxf
                call "%%f"
                if errorlevel 1 (
                    echo   [!] Failed to load: %%~nxf
                )
            )
        )
    )
    echo.
) else (
    echo [!] Config directory not found: %CONF_DIR%
    echo.
)

:: call %USERPROFILE%\.config\cmd\conf.d\01-environment.cmd

:: ===========================================
:: Register function macros.
:: ===========================================
set "FUNCTIONS_DIR=%~dp0functions"

if exist "%FUNCTIONS_DIR%" (
    echo [functions]
    if /i "%CMD_INIT_LOAD_FUNCTION_FILES%"=="1" (
        for %%e in (cmd bat) do (
            for %%f in ("%FUNCTIONS_DIR%\*.%%e") do (
                if exist "%%f" (
                    echo   [+] %%~nxf
                    call "%%f"
                    if errorlevel 1 (
                        echo   [!] Failed to load: %%~nxf
                    )
                )
            )
        )
    ) else (
        echo   [+] builtin function macros
        call :register_builtin_functions
        if errorlevel 1 (
            echo   [!] Failed to register function macros
        )
    )
    echo.
) else (
    echo [!] Functions directory not found: %FUNCTIONS_DIR%
    echo.
)

echo ================================
echo CMD configuration loaded.
echo ================================
echo.
exit /b 0

:register_builtin_functions
set "CMD_SRC=%USERPROFILE%\.config\cmd\src"
doskey cat=%CMD_SRC%\cat.cmd $*
doskey cmac=%CMD_SRC%\cmac.cmd $*
doskey cma=%CMD_SRC%\cmac.cmd $*
doskey colors=echo. $T echo 0 = Black     8 = Gray $T echo 1 = Blue      9 = Light Blue $T echo 2 = Green     A = Light Green $T echo 3 = Aqua      B = Light Aqua $T echo 4 = Red       C = Light Red $T echo 5 = Purple    D = Light Purple $T echo 6 = Yellow    E = Light Yellow $T echo 7 = White     F = Bright White
doskey setcolor=color $*
doskey cp=%CMD_SRC%\cp.cmd $*
doskey head=%CMD_SRC%\head.cmd $*
doskey ln=%CMD_SRC%\ln.cmd $*
doskey mcc=%CMD_SRC%\mcc.cmd $*
doskey md=%CMD_SRC%\md.cmd $*
doskey mv=%CMD_SRC%\mv.cmd $*
doskey proxy=%CMD_SRC%\proxy.cmd $*
doskey rm=%CMD_SRC%\rm.cmd $*
doskey rovo=%CMD_SRC%\rovo.cmd $*
doskey sort=%CMD_SRC%\sort.cmd $*
doskey tail=%CMD_SRC%\tail.cmd $*
doskey touch=%CMD_SRC%\touch.cmd $*
doskey uniq=%CMD_SRC%\uniq.cmd $*
doskey unproxy=%CMD_SRC%\unproxy.cmd
doskey wc=%CMD_SRC%\wc.cmd $*
exit /b 0
