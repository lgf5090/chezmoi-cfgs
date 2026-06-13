@echo off
:: Intelligent Claude Code function with multi-provider support
:: Supports dynamic base_url configuration via environment variables
:: Usage:
::   mcc <provider_alias> [api_key_suffix] [-r|--resume] [-m|--model <model_name>]
::   mcc -l|--list                                       # List all providers

setlocal enabledelayedexpansion

:: Provider configuration mapping table
:: Format: alias -> default_base_url|env_var_prefix|base_url_env_var|model_name|small_model_name

:: Check if list command
if "%~1"=="-l" goto :show_list
if "%~1"=="--list" goto :show_list

:: Check parameter count
if "%~1"=="" (
    echo Error: Must specify provider
    echo Available providers:
    echo   tr, agentrouter  -^> https://agentrouter.org
    echo   yr, anyrouter    -^> https://anyrouter.top
    echo   ds, deepseek     -^> https://api.deepseek.com/anthropic
    echo   km, kimi         -^> https://api.moonshot.cn/anthropic
    echo   glm              -^> https://open.bigmodel.cn/api/anthropic
    echo   sf, siliconflow  -^> https://api.siliconflow.cn/
    echo Usage: mcc ^<provider^> [api_key_suffix] [-r^|--resume] [-m^|--model ^<model_name^>] ^| mcc -l^|--list
    exit /b 1
)

set "provider_alias=%~1"
set "api_key_suffix="
set "resume_flag="
set "custom_model="
set "base_url="
set "default_base_url="
set "base_url_env_var="
set "env_var_prefix="
set "model_name="
set "small_model_name="

:: Parse provider configuration
if /i "%provider_alias%"=="tr" goto :set_agentrouter
if /i "%provider_alias%"=="agentrouter" goto :set_agentrouter
if /i "%provider_alias%"=="yr" goto :set_anyrouter
if /i "%provider_alias%"=="anyrouter" goto :set_anyrouter
if /i "%provider_alias%"=="ds" goto :set_deepseek
if /i "%provider_alias%"=="deepseek" goto :set_deepseek
if /i "%provider_alias%"=="km" goto :set_kimi
if /i "%provider_alias%"=="kimi" goto :set_kimi
if /i "%provider_alias%"=="glm" goto :set_glm
if /i "%provider_alias%"=="sf" goto :set_siliconflow
if /i "%provider_alias%"=="siliconflow" goto :set_siliconflow

echo Error: Unknown provider '%provider_alias%'
echo Available providers:
echo   tr, agentrouter  -^> https://agentrouter.org
echo   yr, anyrouter    -^> https://anyrouter.top
echo   ds, deepseek     -^> https://api.deepseek.com/anthropic
echo   km, kimi         -^> https://api.moonshot.cn/anthropic
echo   glm              -^> https://open.bigmodel.cn/api/anthropic
echo   sf, siliconflow  -^> https://api.siliconflow.cn/
exit /b 1

:set_agentrouter
set "default_base_url=https://agentrouter.org"
set "env_var_prefix=AGENTROUTER_API_KEY"
set "base_url_env_var=AGENTROUTER_BASE_URL"
set "model_name="
set "small_model_name="
goto :resolve_base_url

:set_anyrouter
set "default_base_url=https://anyrouter.top"
set "env_var_prefix=ANYROUTER_API_KEY"
set "base_url_env_var=ANYROUTER_BASE_URL"
set "model_name="
set "small_model_name="
goto :resolve_base_url

:set_deepseek
set "default_base_url=https://api.deepseek.com/anthropic"
set "env_var_prefix=DEEPSEEK_API_KEY"
set "base_url_env_var=DEEPSEEK_BASE_URL"
set "model_name=deepseek-chat"
set "small_model_name=deepseek-chat"
goto :resolve_base_url

:set_kimi
set "default_base_url=https://api.moonshot.cn/anthropic"
set "env_var_prefix=MOONSHOT_API_KEY"
set "base_url_env_var=MOONSHOT_BASE_URL"
set "model_name=kimi-k2-0905"
set "small_model_name=kimi-k2-0905"
goto :resolve_base_url

:set_glm
set "default_base_url=https://open.bigmodel.cn/api/anthropic"
set "env_var_prefix=GLM_API_KEY"
set "base_url_env_var=GLM_BASE_URL"
set "model_name=GLM-4.6"
set "small_model_name=GLM-4.6"
goto :resolve_base_url

:set_siliconflow
set "default_base_url=https://api.siliconflow.cn/"
set "env_var_prefix=SILICONFLOW_API_KEY"
set "base_url_env_var=SILICONFLOW_BASE_URL"
set "model_name=moonshotai/Kimi-K2-Instruct-0905"
set "small_model_name=moonshotai/Kimi-K2-Instruct-0905"
goto :resolve_base_url

:: Resolve base_url: prioritize environment variable, otherwise use default
:resolve_base_url
call set "base_url=%%%base_url_env_var%%%"
if defined base_url (
    echo Using base URL from %base_url_env_var%: !base_url!
) else (
    set "base_url=!default_base_url!"
    echo Using default base URL: !base_url!
)
goto :parse_args

:: Parse remaining parameters
:parse_args
shift
:parse_loop
if "%~1"=="" goto :setup_env

if /i "%~1"=="-r" (
    set "resume_flag= --resume"
    shift
    goto :parse_loop
)
if /i "%~1"=="--resume" (
    set "resume_flag= --resume"
    shift
    goto :parse_loop
)
if /i "%~1"=="-m" (
    if "%~2"=="" (
        echo Error: -m^|--model requires a model name argument
        exit /b 1
    )
    set "custom_model=%~2"
    shift
    shift
    goto :parse_loop
)
if /i "%~1"=="--model" (
    if "%~2"=="" (
        echo Error: -m^|--model requires a model name argument
        exit /b 1
    )
    set "custom_model=%~2"
    shift
    shift
    goto :parse_loop
)

:: If not an option, then it's an API key suffix
if not defined api_key_suffix (
    set "api_key_suffix=%~1"
    shift
    goto :parse_loop
) else (
    echo Error: Multiple API key suffixes specified
    exit /b 1
)

:: Set environment variables
:setup_env
:: Resolve API key with delayed expansion
if defined api_key_suffix (
    call set "api_key=%%%env_var_prefix%_%api_key_suffix%%%"
    if not defined api_key (
        endlocal
        echo Error: Environment variable %env_var_prefix%_%api_key_suffix% not found
        echo Make sure you have set: set %env_var_prefix%_%api_key_suffix%=your_api_key
        exit /b 1
    )
) else (
    call set "api_key=%%%env_var_prefix%%%"
    if not defined api_key (
        endlocal
        echo Error: Environment variable %env_var_prefix% not found
        echo Make sure you have set: set %env_var_prefix%=your_api_key
        exit /b 1
    )
)

:: Export variables before endlocal
endlocal & (
    set "ANTHROPIC_BASE_URL=%base_url%"
    set "ANTHROPIC_AUTH_TOKEN=%api_key%"
    if defined custom_model (
        set "ANTHROPIC_MODEL=%custom_model%"
        set "ANTHROPIC_SMALL_FAST_MODEL=%custom_model%"
        set "API_TIMEOUT_MS=600000"
        set "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
    ) else if defined model_name (
        set "ANTHROPIC_MODEL=%model_name%"
        set "ANTHROPIC_SMALL_FAST_MODEL=%small_model_name%"
        set "API_TIMEOUT_MS=600000"
        set "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
    )
)

:: Display info
echo Using API key: %ANTHROPIC_AUTH_TOKEN%
if defined custom_model (
    echo Using custom model: %custom_model%
) else if defined model_name (
    echo Using model: %model_name%
)
echo Connecting to: %ANTHROPIC_BASE_URL%

:: Execute claude command
claude --dangerously-skip-permissions%resume_flag%
exit /b %errorlevel%

:show_list
setlocal enabledelayedexpansion
echo Available Claude Code providers:
echo ================================

:: AgentRouter
set "url_env_var=AGENTROUTER_BASE_URL"
call set "actual_url=%%%url_env_var%%%"
if defined actual_url (
    echo   tr, agentrouter  -^> !actual_url! [from %url_env_var%]
) else (
    echo   tr, agentrouter  -^> https://agentrouter.org
)
echo                        API Key Env: AGENTROUTER_API_KEY, URL Env: AGENTROUTER_BASE_URL

:: AnyRouter
set "url_env_var=ANYROUTER_BASE_URL"
call set "actual_url=%%%url_env_var%%%"
if defined actual_url (
    echo   yr, anyrouter    -^> !actual_url! [from %url_env_var%]
) else (
    echo   yr, anyrouter    -^> https://anyrouter.top
)
echo                        API Key Env: ANYROUTER_API_KEY, URL Env: ANYROUTER_BASE_URL

:: DeepSeek
set "url_env_var=DEEPSEEK_BASE_URL"
call set "actual_url=%%%url_env_var%%%"
if defined actual_url (
    echo   ds, deepseek     -^> !actual_url! [from %url_env_var%]
) else (
    echo   ds, deepseek     -^> https://api.deepseek.com/anthropic
)
echo                        API Key Env: DEEPSEEK_API_KEY, URL Env: DEEPSEEK_BASE_URL

:: Kimi
set "url_env_var=MOONSHOT_BASE_URL"
call set "actual_url=%%%url_env_var%%%"
if defined actual_url (
    echo   km, kimi         -^> !actual_url! [from %url_env_var%]
) else (
    echo   km, kimi         -^> https://api.moonshot.cn/anthropic
)
echo                        API Key Env: MOONSHOT_API_KEY, URL Env: MOONSHOT_BASE_URL

:: GLM
set "url_env_var=GLM_BASE_URL"
call set "actual_url=%%%url_env_var%%%"
if defined actual_url (
    echo   glm              -^> !actual_url! [from %url_env_var%]
) else (
    echo   glm              -^> https://open.bigmodel.cn/api/anthropic
)
echo                        API Key Env: GLM_API_KEY, URL Env: GLM_BASE_URL

:: SiliconFlow
set "url_env_var=SILICONFLOW_BASE_URL"
call set "actual_url=%%%url_env_var%%%"
if defined actual_url (
    echo   sf, siliconflow  -^> !actual_url! [from %url_env_var%]
) else (
    echo   sf, siliconflow  -^> https://api.siliconflow.cn/
)
echo                        API Key Env: SILICONFLOW_API_KEY, URL Env: SILICONFLOW_BASE_URL

endlocal
echo.
echo Usage examples:
echo   mcc tr                    # Use agentrouter with default key
echo   mcc yr 5433               # Use anyrouter with ANYROUTER_API_KEY_5433
echo   mcc ds 5090 -m deepseek-reasoner  # Use deepseek with specific model
echo   mcc agentrouter -r        # Use agentrouter with resume flag
echo   mcc anyrouter 1234 -r     # Use anyrouter with specific key and resume
echo   mcc -l, --list            # Show this provider list
echo.
echo Environment variable examples:
echo   set AGENTROUTER_BASE_URL=https://custom.agentrouter.org
echo   set DEEPSEEK_BASE_URL=https://custom.deepseek.com
exit /b 0