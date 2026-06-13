@echo off
:: md.cmd - Unix-style directory creation for Windows
:: This file defines a doskey macro that calls the actual md script

:: Define the md doskey macro
doskey md=%USERPROFILE%\.config\cmd\src\md.cmd $*

:: Exit successfully without running the script logic
exit /b 0
