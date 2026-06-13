@echo off
:: Intelligent Claude Code function with multi-provider support
:: This file defines a doskey macro that calls the actual mcc script

:: Define the mcc doskey macro
doskey mcc=%USERPROFILE%\.config\cmd\src\mcc.cmd $*

:: Exit successfully without running the script logic
exit /b 0
