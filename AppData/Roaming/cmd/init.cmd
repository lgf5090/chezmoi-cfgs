@echo off
:: CMD 主配置文件
:: 自动加载 conf.d 和 functions 目录下的所有 .cmd 和 .bat 文件

:: 设置 UTF-8 编码（可选，避免中文乱码）
chcp 65001 >nul 2>&1

echo ================================
echo 正在加载 CMD 配置...
echo ================================
echo.

:: ===========================================
:: 加载配置文件（conf.d 目录）
:: ===========================================
set "CONF_DIR=%~dp0conf.d"

if exist "%CONF_DIR%" (
    echo [配置文件]
    for %%e in (cmd bat) do (
        for %%f in ("%CONF_DIR%\*.%%e") do (
            if exist "%%f" (
                echo   [+] %%~nxf
                call "%%f"
                if errorlevel 1 (
                    echo   [!] 加载失败: %%~nxf
                )
            )
        )
    )
    echo.
) else (
    echo [!] 配置目录不存在: %CONF_DIR%
    echo.
)

:: call %USERPROFILE%\.config\cmd\conf.d\01-environment.cmd

:: ===========================================
:: 加载函数库（functions 目录）
:: ===========================================
set "FUNCTIONS_DIR=%~dp0functions"

if exist "%FUNCTIONS_DIR%" (
    echo [函数库]
    for %%e in (cmd bat) do (
        for %%f in ("%FUNCTIONS_DIR%\*.%%e") do (
            if exist "%%f" (
                echo   [+] %%~nxf
                call "%%f"
                if errorlevel 1 (
                    echo   [!] 加载失败: %%~nxf
                )
            )
        )
    )
    echo.
) else (
    echo [!] 函数库目录不存在: %FUNCTIONS_DIR%
    echo.
)

echo ================================
echo CMD 配置加载完成！
echo ================================
echo.