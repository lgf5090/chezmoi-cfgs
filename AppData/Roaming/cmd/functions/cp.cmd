@echo off
:: cp.cmd - Unix-style copy for Windows
:: This file defines a doskey macro that calls the actual cp script

:: Define the cp doskey macro
doskey cp=%USERPROFILE%\.config\cmd\src\cp.cmd $*

:: Exit successfully without running the script logic
exit /b 0
