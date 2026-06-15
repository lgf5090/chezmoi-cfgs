@echo off
:: Launch Neovim with the nvim-dev config

setlocal
set "NVIM_APPNAME=nvim-dev"
nvim %*
exit /b %ERRORLEVEL%
