@echo off
:: wc.cmd - Unix-style word count for Windows
:: This file defines a doskey macro that calls the actual wc script

:: Define the wc doskey macro
doskey wc=%USERPROFILE%\.config\cmd\src\wc.cmd $*

:: Exit successfully without running the script logic
exit /b 0
