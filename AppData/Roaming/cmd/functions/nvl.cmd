@echo off
:: nvl.cmd - Launch Neovim with the nvim-lite config
:: This file defines a doskey macro that calls the actual nvl script

:: Define the nvl doskey macro
doskey nvl=%USERPROFILE%\.config\cmd\src\nvl.cmd $*

:: Exit successfully without running the script logic
exit /b 0
