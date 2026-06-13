@echo off
:: sort.cmd - Unix-style sort for Windows
:: This file defines a doskey macro that calls the actual sort script

:: Define the sort doskey macro
doskey sort=%USERPROFILE%\.config\cmd\src\sort.cmd $*

:: Exit successfully without running the script logic
exit /b 0
