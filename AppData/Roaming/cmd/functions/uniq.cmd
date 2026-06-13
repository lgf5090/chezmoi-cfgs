@echo off
:: uniq.cmd - Unix-style uniq for Windows
:: This file defines a doskey macro that calls the actual uniq script

:: Define the uniq doskey macro
doskey uniq=%USERPROFILE%\.config\cmd\src\uniq.cmd $*

:: Exit successfully without running the script logic
exit /b 0
