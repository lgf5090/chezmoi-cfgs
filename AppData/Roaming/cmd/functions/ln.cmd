@echo off
:: ln.cmd - Unix-style symbolic link creation for Windows
:: This file defines a doskey macro that calls the actual ln script

:: Define the ln doskey macro
doskey ln=%USERPROFILE%\.config\cmd\src\ln.cmd $*

:: Exit successfully without running the script logic
exit /b 0
