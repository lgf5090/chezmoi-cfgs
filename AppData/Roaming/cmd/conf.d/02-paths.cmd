@echo off
:: PATH configuration - Windows version (Ultimate performance optimization)
:: Corresponds to PowerShell's 02-paths.ps1

:: Build new PATH, set it once at the end (avoid multiple function calls)
set "NEW_PATH="

:: ============================================
:: User local paths (highest priority)
:: ============================================
if exist "%USERPROFILE%\.local\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\.local\bin;"
if exist "%USERPROFILE%\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\bin;"
if exist "%USERPROFILE%\AppData\Local\Programs\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\AppData\Local\Programs\bin;"

:: ============================================
:: Node.js 开发工具路径
:: ============================================
if exist "%APPDATA%\npm" set "NEW_PATH=%NEW_PATH%%APPDATA%\npm;"
if exist "%USERPROFILE%\.npm-global" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\.npm-global;"
if exist "%USERPROFILE%\.npm-global\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\.npm-global\bin;"
if defined PNPM_HOME if exist "%PNPM_HOME%" set "NEW_PATH=%NEW_PATH%%PNPM_HOME%;"
if exist "%USERPROFILE%\.pnpm-global\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\.pnpm-global\bin;"
if exist "%USERPROFILE%\.yarn\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\.yarn\bin;"
if exist "%USERPROFILE%\.config\yarn\global\node_modules\.bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\.config\yarn\global\node_modules\.bin;"
if defined BUN_HOME if exist "%BUN_HOME%\bin" set "NEW_PATH=%NEW_PATH%%BUN_HOME%\bin;"
if exist "%USERPROFILE%\.bun\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\.bun\bin;"
if defined DENO_HOME if exist "%DENO_HOME%\bin" set "NEW_PATH=%NEW_PATH%%DENO_HOME%\bin;"
if exist "%USERPROFILE%\.deno\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\.deno\bin;"
if exist "%USERPROFILE%\.volta\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\.volta\bin;"
if exist "%LOCALAPPDATA%\Volta\bin" set "NEW_PATH=%NEW_PATH%%LOCALAPPDATA%\Volta\bin;"

:: ============================================
:: Python development tools paths
:: ============================================
if defined ANACONDA_HOME (
    if exist "%ANACONDA_HOME%" set "NEW_PATH=%NEW_PATH%%ANACONDA_HOME%;"
    if exist "%ANACONDA_HOME%\Scripts" set "NEW_PATH=%NEW_PATH%%ANACONDA_HOME%\Scripts;"
    if exist "%ANACONDA_HOME%\Library\bin" set "NEW_PATH=%NEW_PATH%%ANACONDA_HOME%\Library\bin;"
)

:: Common conda locations (check only the first one that exists)
if exist "%USERPROFILE%\anaconda3" (
    set "NEW_PATH=%NEW_PATH%%USERPROFILE%\anaconda3;"
    if exist "%USERPROFILE%\anaconda3\Scripts" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\anaconda3\Scripts;"
    if exist "%USERPROFILE%\anaconda3\Library\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\anaconda3\Library\bin;"
) else if exist "%USERPROFILE%\miniconda3" (
    set "NEW_PATH=%NEW_PATH%%USERPROFILE%\miniconda3;"
    if exist "%USERPROFILE%\miniconda3\Scripts" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\miniconda3\Scripts;"
    if exist "%USERPROFILE%\miniconda3\Library\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\miniconda3\Library\bin;"
)

if exist "%APPDATA%\Python\Scripts" set "NEW_PATH=%NEW_PATH%%APPDATA%\Python\Scripts;"
if exist "%USERPROFILE%\.poetry\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\.poetry\bin;"
if defined POETRY_HOME if exist "%POETRY_HOME%\bin" set "NEW_PATH=%NEW_PATH%%POETRY_HOME%\bin;"
if exist "%APPDATA%\pypoetry\venv\Scripts" set "NEW_PATH=%NEW_PATH%%APPDATA%\pypoetry\venv\Scripts;"

if defined PYENV_ROOT (
    if exist "%PYENV_ROOT%\bin" set "NEW_PATH=%NEW_PATH%%PYENV_ROOT%\bin;"
    if exist "%PYENV_ROOT%\shims" set "NEW_PATH=%NEW_PATH%%PYENV_ROOT%\shims;"
)

:: ============================================
:: Rust/Cargo
:: ============================================
if exist "%USERPROFILE%\.cargo\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\.cargo\bin;"

:: ============================================
:: Go development tools paths
:: ============================================
if exist "%USERPROFILE%\go\bin" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\go\bin;"
if defined GOPATH if exist "%GOPATH%\bin" set "NEW_PATH=%NEW_PATH%%GOPATH%\bin;"
if defined GOROOT if exist "%GOROOT%\bin" set "NEW_PATH=%NEW_PATH%%GOROOT%\bin;"
if exist "C:\Go\bin" set "NEW_PATH=%NEW_PATH%C:\Go\bin;"
if exist "%ProgramFiles%\Go\bin" set "NEW_PATH=%NEW_PATH%%ProgramFiles%\Go\bin;"

:: ============================================
:: Windows package managers paths
:: ============================================
if exist "%USERPROFILE%\scoop\shims" set "NEW_PATH=%NEW_PATH%%USERPROFILE%\scoop\shims;"
if defined ChocolateyInstall if exist "%ChocolateyInstall%\bin" set "NEW_PATH=%NEW_PATH%%ChocolateyInstall%\bin;"
if exist "%ProgramData%\chocolatey\bin" set "NEW_PATH=%NEW_PATH%%ProgramData%\chocolatey\bin;"

:: ============================================
:: Development tools paths
:: ============================================
if exist "%LOCALAPPDATA%\Programs\Microsoft VS Code\bin" set "NEW_PATH=%NEW_PATH%%LOCALAPPDATA%\Programs\Microsoft VS Code\bin;"
if exist "%ProgramFiles%\Microsoft VS Code\bin" set "NEW_PATH=%NEW_PATH%%ProgramFiles%\Microsoft VS Code\bin;"
if exist "%ProgramFiles%\Git\cmd" set "NEW_PATH=%NEW_PATH%%ProgramFiles%\Git\cmd;"
if exist "%ProgramFiles%\Git\bin" set "NEW_PATH=%NEW_PATH%%ProgramFiles%\Git\bin;"

:: ============================================
:: Windows Apps paths
:: ============================================
if exist "%LOCALAPPDATA%\Microsoft\WindowsApps" set "NEW_PATH=%NEW_PATH%%LOCALAPPDATA%\Microsoft\WindowsApps;"

:: ============================================
:: Apply new PATH (preserve existing system PATH)
:: ============================================
if defined NEW_PATH set "PATH=%NEW_PATH%%PATH%"