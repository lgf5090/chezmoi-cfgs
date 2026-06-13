@echo off
:: Unproxy configuration script
:: Clears all proxy environment variables

:: Clear proxy environment variables
set "http_proxy="
set "https_proxy="
set "all_proxy="
set "no_proxy="

echo Proxy settings cleared

exit /b 0
