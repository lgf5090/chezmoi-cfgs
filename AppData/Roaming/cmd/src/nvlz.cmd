@echo off
:: Launch Neovim with the nvim-lazy config

setlocal
set "NVIM_APPNAME=nvim-lazy"
nvim %*
exit /b %ERRORLEVEL%
