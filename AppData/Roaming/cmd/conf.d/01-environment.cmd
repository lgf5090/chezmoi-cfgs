@echo off
:: 极速环境变量配置 - 只设置基本变量

:: 基础变量
set "HOME=%USERPROFILE%"
set "EDITOR=code"
set "VISUAL=code"
set "GIT_EDITOR=code"
set "PAGER=more"

:: 开发环境基础路径
set "NODE_ENV=development"
set "NPM_CONFIG_PREFIX=%USERPROFILE%\.npm-global"
set "PNPM_HOME=%USERPROFILE%\.pnpm-global"
set "BUN_HOME=%USERPROFILE%\.bun"
set "GOPATH=%USERPROFILE%\go"
set "CARGO_HOME=%USERPROFILE%\.cargo"
set "RUSTUP_HOME=%USERPROFILE%\.rustup"

:: Windows 包管理器
set "ChocolateyInstall=%ProgramData%\chocolatey"
set "SCOOP=%USERPROFILE%\scoop"

:: 其他必要变量
set "PSModulePath=%USERPROFILE%\Documents\PowerShell\Modules;%PSModulePath%"


:: ai apik
:: mcp servers
:: https://smithery.ai/account/api-keys
:: set "MCP_SMITHERY_API_KEY=xxx"

:: github
:: "GITHUB_API_KEY=xxx"


