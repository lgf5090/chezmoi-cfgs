@echo off
:: mv.cmd - Unix-style move/rename for Windows
:: This file defines a doskey macro that calls the actual mv script

:: Define the mv doskey macro
doskey mv=%USERPROFILE%\.config\cmd\src\mv.cmd $*

:: Exit successfully without running the script logic
exit /b 0
