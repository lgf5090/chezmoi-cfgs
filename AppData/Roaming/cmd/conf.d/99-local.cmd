@echo off
:: Local specific configuration - Windows version
:: Corresponds to PowerShell's 99-local.ps1
:: For machine-specific settings, should not be committed to version control

:: ============================================
:: Example: Local development environment configuration
:: ============================================
:: if exist "C:\CustomTools\bin" (
::     set "PATH=%PATH%;C:\CustomTools\bin"
:: )

:: ============================================
:: Example: Company-specific proxy settings
:: ============================================
:: if "%COMPUTERNAME%"=="WORK-MACHINE" (
::     set "HTTP_PROXY=http://proxy.company.com:8080"
::     set "HTTPS_PROXY=http://proxy.company.com:8080"
::     set "NO_PROXY=localhost,127.0.0.1"
:: )

:: ============================================
:: Example: Specific project environment variables
:: ============================================
:: if exist "%USERPROFILE%\.env.local.cmd" (
::     call "%USERPROFILE%\.env.local.cmd"
:: )

:: ============================================
:: Local custom aliases
:: ============================================
:: doskey work=cd /d "C:\Work\Projects"
:: doskey project=cd /d "C:\Projects\MyProject"
:: doskey devserver=cd /d "C:\Dev\Server" $T npm run dev

:: ============================================
:: Example: Work directory shortcuts
:: ============================================
:: if exist "C:\Work" (
::     doskey work=cd /d "C:\Work\$*"
:: )
::
:: if exist "C:\Projects" (
::     doskey proj=cd /d "C:\Projects\$*"
:: )

:: ============================================
:: Example: Company internal tools configuration
:: ============================================
:: if exist "%USERPROFILE%\CompanyTools" (
::     set "PATH=%PATH%;%USERPROFILE%\CompanyTools\bin"
::     set "COMPANY_TOOLS_HOME=%USERPROFILE%\CompanyTools"
:: )

:: ============================================
:: Example: VPN or network configuration
:: ============================================
:: if "%USERDOMAIN%"=="COMPANY" (
::     set "VPN_CONFIG=%USERPROFILE%\vpn-config.ovpn"
:: )

:: echo Local configuration loaded (if any)