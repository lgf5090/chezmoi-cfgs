@echo off
:: Intelligent Rovo function with multi-account support
:: Usage:
::   rovo <account_alias> [-r|--restore]
::   rovo -l|--list                          # List all accounts

setlocal enabledelayedexpansion

:: Account configuration mapping table
:: Format: alias -> env_var_suffix|email

:: Check if list command
if "%~1"=="-l" goto :show_list
if "%~1"=="--list" goto :show_list

:: Check parameter count
if "%~1"=="" (
    echo Error: Must specify account alias
    echo Available accounts:
    echo   q5090        -^> lgf5090@qq.com
    echo   o5090        -^> lgf5090@outlook.com
    echo   5090         -^> lgf5090@gmail.com
    echo   4591         -^> lgf14591@gmail.com
    echo   o4591        -^> lgf4591@outlook.com
    echo   5481         -^> lgf5481@gmail.com
    echo   4470         -^> lgf4470@gmail.com
    echo   9697         -^> lgf9697@gmail.com
    echo   0932         -^> lgf0932@gmail.com
    echo   6491         -^> lgf6491@gmail.com
    echo   2663         -^> lgf42663@gmail.com
    echo   o0932        -^> lgf60932@outlook.com
    echo   o6491        -^> lgf6491@outlook.com
    echo   o0709        -^> lgf0709@outlook.com
    echo   follieros    -^> follieros@hotmail.com
    echo   quicklywin   -^> quicklywin@hotmail.com
    echo   streamlit    -^> streamlit@hotmail.com
    echo Usage: rovo ^<account^> [-r^|--restore] ^| rovo -l^|--list
    exit /b 1
)

set "account_alias=%~1"
set "restore_flag="
set "env_suffix="
set "email="

:: Parse account configuration
if /i "%account_alias%"=="q5090" (set "env_suffix=Q5090" & set "email=lgf5090@qq.com" & goto :parse_args)
if /i "%account_alias%"=="o5090" (set "env_suffix=O5090" & set "email=lgf5090@outlook.com" & goto :parse_args)
if /i "%account_alias%"=="5090" (set "env_suffix=5090" & set "email=lgf5090@gmail.com" & goto :parse_args)
if /i "%account_alias%"=="4591" (set "env_suffix=4591" & set "email=lgf14591@gmail.com" & goto :parse_args)
if /i "%account_alias%"=="o4591" (set "env_suffix=O4591" & set "email=lgf4591@outlook.com" & goto :parse_args)
if /i "%account_alias%"=="5481" (set "env_suffix=5481" & set "email=lgf5481@gmail.com" & goto :parse_args)
if /i "%account_alias%"=="4470" (set "env_suffix=4470" & set "email=lgf4470@gmail.com" & goto :parse_args)
if /i "%account_alias%"=="9697" (set "env_suffix=9697" & set "email=lgf9697@gmail.com" & goto :parse_args)
if /i "%account_alias%"=="0932" (set "env_suffix=0932" & set "email=lgf0932@gmail.com" & goto :parse_args)
if /i "%account_alias%"=="6491" (set "env_suffix=6491" & set "email=lgf6491@gmail.com" & goto :parse_args)
if /i "%account_alias%"=="2663" (set "env_suffix=2663" & set "email=lgf42663@gmail.com" & goto :parse_args)
if /i "%account_alias%"=="o0932" (set "env_suffix=O0932" & set "email=lgf60932@outlook.com" & goto :parse_args)
if /i "%account_alias%"=="o6491" (set "env_suffix=O6491" & set "email=lgf6491@outlook.com" & goto :parse_args)
if /i "%account_alias%"=="o0709" (set "env_suffix=O0709" & set "email=lgf0709@outlook.com" & goto :parse_args)
if /i "%account_alias%"=="follieros" (set "env_suffix=FOLLIEROS" & set "email=follieros@hotmail.com" & goto :parse_args)
if /i "%account_alias%"=="quicklywin" (set "env_suffix=QUICKLYWIN" & set "email=quicklywin@hotmail.com" & goto :parse_args)
if /i "%account_alias%"=="streamlit" (set "env_suffix=STREAMLIT" & set "email=streamlit@hotmail.com" & goto :parse_args)

echo Error: Unknown account alias '%account_alias%'
echo Available accounts:
echo   q5090        -^> lgf5090@qq.com
echo   o5090        -^> lgf5090@outlook.com
echo   5090         -^> lgf5090@gmail.com
echo   4591         -^> lgf14591@gmail.com
echo   o4591        -^> lgf4591@outlook.com
echo   5481         -^> lgf5481@gmail.com
echo   4470         -^> lgf4470@gmail.com
echo   9697         -^> lgf9697@gmail.com
echo   0932         -^> lgf0932@gmail.com
echo   6491         -^> lgf6491@gmail.com
echo   2663         -^> lgf42663@gmail.com
echo   o0932        -^> lgf60932@outlook.com
echo   o6491        -^> lgf6491@outlook.com
echo   o0709        -^> lgf0709@outlook.com
echo   follieros    -^> follieros@hotmail.com
echo   quicklywin   -^> quicklywin@hotmail.com
echo   streamlit    -^> streamlit@hotmail.com
echo Tip: Use 'rovo -l' to see all available accounts
exit /b 1

:: Parse remaining parameters
:parse_args
shift
:parse_loop
if "%~1"=="" goto :execute

if /i "%~1"=="-r" (
    set "restore_flag= --restore"
    shift
    goto :parse_loop
)
if /i "%~1"=="--restore" (
    set "restore_flag= --restore"
    shift
    goto :parse_loop
)

echo Error: Unknown option '%~1'
echo Usage: rovo ^<account^> [-r^|--restore]
exit /b 1

:: Execute rovo command
:execute
:: Check if environment variable exists
set "env_var_name=ROVO_API_KEY_%env_suffix%"
call set "token=%%%env_var_name%%%"
if not defined token (
    endlocal
    echo Error: Environment variable %env_var_name% not found
    echo Please set it with: set %env_var_name%=your_token_here
    exit /b 1
)

endlocal & set "final_token=%token%" & set "final_email=%email%" & set "final_restore=%restore_flag%"

echo Connecting with account: %final_email%
echo Using environment variable: %env_var_name%
echo Executing: acli rovodev auth login + run%final_restore%

:: Execute command (pipe token to acli)
echo %final_token%| acli rovodev auth login --email "%final_email%" --token && acli rovodev run%final_restore%

exit /b %errorlevel%

:show_list
echo Available Rovo accounts:
echo =======================
echo   q5090        -^> lgf5090@qq.com            (Env: ROVO_API_KEY_Q5090)
echo   o5090        -^> lgf5090@outlook.com       (Env: ROVO_API_KEY_O5090)
echo   5090         -^> lgf5090@gmail.com         (Env: ROVO_API_KEY_5090)
echo   4591         -^> lgf14591@gmail.com        (Env: ROVO_API_KEY_4591)
echo   o4591        -^> lgf4591@outlook.com       (Env: ROVO_API_KEY_O4591)
echo   5481         -^> lgf5481@gmail.com         (Env: ROVO_API_KEY_5481)
echo   4470         -^> lgf4470@gmail.com         (Env: ROVO_API_KEY_4470)
echo   9697         -^> lgf9697@gmail.com         (Env: ROVO_API_KEY_9697)
echo   0932         -^> lgf0932@gmail.com         (Env: ROVO_API_KEY_0932)
echo   6491         -^> lgf6491@gmail.com         (Env: ROVO_API_KEY_6491)
echo   2663         -^> lgf42663@gmail.com        (Env: ROVO_API_KEY_2663)
echo   o0932        -^> lgf60932@outlook.com      (Env: ROVO_API_KEY_O0932)
echo   o6491        -^> lgf6491@outlook.com       (Env: ROVO_API_KEY_O6491)
echo   o0709        -^> lgf0709@outlook.com       (Env: ROVO_API_KEY_O0709)
echo   follieros    -^> follieros@hotmail.com     (Env: ROVO_API_KEY_FOLLIEROS)
echo   quicklywin   -^> quicklywin@hotmail.com    (Env: ROVO_API_KEY_QUICKLYWIN)
echo   streamlit    -^> streamlit@hotmail.com     (Env: ROVO_API_KEY_STREAMLIT)
echo.
echo Environment variables setup example:
echo   set ROVO_API_KEY_Q5090=your_token_here
echo   set ROVO_API_KEY_4591=your_token_here
echo.
echo Usage examples:
echo   rovo q5090              # Use lgf5090@qq.com account
echo   rovo 4591 -r            # Use lgf14591@gmail.com with restore
echo   rovo follieros --restore # Use follieros@hotmail.com with restore
echo   rovo -l, --list         # Show this account list
exit /b 0
