@echo off
:: nvd.cmd - Launch Neovim with the nvim-dev config
:: This file defines a doskey macro that calls the actual nvd script

:: Define the nvd doskey macro
doskey nvd=%USERPROFILE%\.config\cmd\src\nvd.cmd $*

:: Exit successfully without running the script logic
exit /b 0
