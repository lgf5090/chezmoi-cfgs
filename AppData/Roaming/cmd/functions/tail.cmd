@echo off
:: tail.cmd - Unix-style tail for Windows
:: This file defines a doskey macro that calls the actual tail script

:: Define the tail doskey macro
doskey tail=%USERPROFILE%\.config\cmd\src\tail.cmd $*

:: Exit successfully without running the script logic
exit /b 0
