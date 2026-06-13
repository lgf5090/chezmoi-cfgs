@echo off
:: head.cmd - Unix-style head for Windows
:: This file defines a doskey macro that calls the actual head script

:: Define the head doskey macro
doskey head=%USERPROFILE%\.config\cmd\src\head.cmd $*

:: Exit successfully without running the script logic
exit /b 0
