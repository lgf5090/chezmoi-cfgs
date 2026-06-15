@echo off
:: nvlz.cmd - Launch Neovim with the nvim-lazy config
:: This file defines a doskey macro that calls the actual nvlz script

:: Define the nvlz doskey macro
doskey nvlz=%USERPROFILE%\.config\cmd\src\nvlz.cmd $*

:: Exit successfully without running the script logic
exit /b 0
