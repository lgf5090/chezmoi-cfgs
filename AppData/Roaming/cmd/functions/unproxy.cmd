@echo off
:: Unproxy configuration function
:: This file defines a doskey macro that calls the actual unproxy script

:: Define the unproxy doskey macro
doskey unproxy=%USERPROFILE%\.config\cmd\src\unproxy.cmd

:: Exit successfully without running the script logic
exit /b 0
