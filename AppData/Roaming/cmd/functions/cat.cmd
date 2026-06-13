@echo off
:: cat.cmd - Unix-style file concatenation for Windows
:: This file defines a doskey macro that calls the actual cat script

:: Define the cat doskey macro
doskey cat=%USERPROFILE%\.config\cmd\src\cat.cmd $*

:: Exit successfully without running the script logic
exit /b 0
