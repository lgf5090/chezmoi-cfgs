@echo off
:: Proxy configuration function
:: This file defines a doskey macro that calls the actual proxy script

:: Define the proxy doskey macro
doskey proxy=%USERPROFILE%\.config\cmd\src\proxy.cmd $*

:: Exit successfully without running the script logic
exit /b 0
