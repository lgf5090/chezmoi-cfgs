@echo off
:: Chezmoi Apply Change - Apply chezmoi changes for files shown in git status
:: This file defines a doskey macro that calls the actual cmac script

:: Define the cmac doskey macro
doskey cmac=%USERPROFILE%\.config\cmd\src\cmac.cmd $*

:: Define the cma alias (short form)
doskey cma=%USERPROFILE%\.config\cmd\src\cmac.cmd $*

:: Exit successfully without running the script logic
exit /b 0


