@echo off
:: Intelligent Rovo function with multi-account support
:: This file defines a doskey macro that calls the actual rovo script

:: Define the rovo doskey macro
doskey rovo=%USERPROFILE%\.config\cmd\src\rovo.cmd $*

:: Exit successfully without running the script logic
exit /b 0
