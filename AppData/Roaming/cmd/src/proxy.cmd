@echo off
:: Proxy configuration script
:: Usage: proxy [port|client_name]
:: Default port: 10808
:: Supported clients: clash, clash-verge, v2ray, nekoray, karing, hiddify

:: Get argument, default to 10808
set "input=%~1"
if "%input%"=="" set "input=10808"

:: Map client names to ports
set "port="
if /i "%input%"=="clash" set "port=7890"
if /i "%input%"=="clash-verge" set "port=7890"
if /i "%input%"=="v2ray" set "port=10808"
if /i "%input%"=="nekoray" set "port=2080"
if /i "%input%"=="karing" set "port=2080"
if /i "%input%"=="hiddify" set "port=2334"

:: If not a known client name, treat as port number
if not defined port set "port=%input%"

:: Validate port is numeric
echo %port%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo Error: Invalid port '%input%'
    echo.
    echo Usage: proxy [port^|client_name]
    echo Supported clients:
    echo   clash, clash-verge  -^> port 7890
    echo   v2ray               -^> port 10808
    echo   nekoray, karing     -^> port 2080
    echo   hiddify             -^> port 2334
    echo Or directly specify a port number
    exit /b 1
)

:: Set proxy environment variables
set "http_proxy=http://127.0.0.1:%port%"
set "https_proxy=http://127.0.0.1:%port%"
set "all_proxy=socks5://127.0.0.1:%port%"
set "no_proxy=localhost,"
echo proxy_set:%port%

exit /b 0
