@echo off
:: Launch Neovim with the nvim-lite config

setlocal
set "NVIM_APPNAME=nvim-lite"
nvim %*
exit /b %ERRORLEVEL%
