@echo off
:: rm.cmd - Unix-style file/directory removal for Windows
:: This file defines a doskey macro that calls the actual rm script

:: Define the rm doskey macro
doskey rm=%USERPROFILE%\.config\cmd\src\rm.cmd $*

:: Exit successfully without running the script logic
exit /b 0
