@echo off
:: touch.cmd - Unix-style file creation for Windows
:: This file defines a doskey macro that calls the actual touch script

:: Define the touch doskey macro
doskey touch=%USERPROFILE%\.config\cmd\src\touch.cmd $*

:: Exit successfully without running the script logic
exit /b 0
