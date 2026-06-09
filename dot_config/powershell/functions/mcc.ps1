#Requires -Version 5.0

# Claude Code 多供应商切换工具（PowerShell 版本）
#
# 用法：
#   mcc <provider> [key_suffix] [-r|--resume] [-m|--model <model>] [-e|--effort max|normal|min]
#   mcc -l | --list                 显示供应商表
#   mcc -h | --help                 显示完整帮助（含场景示例与注意事项）
#
# 新增供应商：在 $_MCC_PROVIDERS 中添加一行即可，补全自动生效。
#
# 加载方式：在 $PROFILE 中 dot-source 本文件，例如：
#   . "$HOME\code\claude-code\single-dotfile\shells\functions\powershell\mcc.ps1"

# ============================================================
# 供应商配置（唯一数据源）
# big_model   -> ANTHROPIC_MODEL / DEFAULT_OPUS / DEFAULT_SONNET
# small_model -> DEFAULT_HAIKU / CLAUDE_CODE_SUBAGENT_MODEL
# 空字符串     -> 不设置模型变量（适用于透传代理）
# ============================================================
$script:_MCC_PROVIDERS = @(
    [PSCustomObject]@{ name = 'agentrouter'; default_url = 'https://agentrouter.org';                api_key_env = 'AGENTROUTER_API_KEY'; base_url_env = 'AGENTROUTER_BASE_URL'; big_model = '';                            small_model = '' }
    [PSCustomObject]@{ name = 'anyrouter';   default_url = 'https://anyrouter.top';                  api_key_env = 'ANYROUTER_API_KEY';   base_url_env = 'ANYROUTER_BASE_URL';   big_model = '';                            small_model = '' }
    [PSCustomObject]@{ name = 'deepseek';    default_url = 'https://api.deepseek.com/anthropic';     api_key_env = 'DEEPSEEK_API_KEY';    base_url_env = 'DEEPSEEK_BASE_URL';    big_model = 'deepseek-v4-pro[1m]';         small_model = 'deepseek-v4-flash' }
    [PSCustomObject]@{ name = 'moonshot';    default_url = 'https://api.moonshot.cn/anthropic';      api_key_env = 'MOONSHOT_API_KEY';    base_url_env = 'MOONSHOT_BASE_URL';    big_model = 'kimi-k2.6';                   small_model = 'kimi-k2.6' }
    [PSCustomObject]@{ name = 'glm';         default_url = 'https://open.bigmodel.cn/api/anthropic'; api_key_env = 'GLM_API_KEY';         base_url_env = 'GLM_BASE_URL';         big_model = 'GLM-5.1';                     small_model = 'GLM-5.1' }
    [PSCustomObject]@{ name = 'siliconflow'; default_url = 'https://api.siliconflow.cn/';            api_key_env = 'SILICONFLOW_API_KEY'; base_url_env = 'SILICONFLOW_BASE_URL'; big_model = 'deepseek-ai/DeepSeek-V4-Pro'; small_model = 'deepseek-ai/DeepSeek-V4-Flash' }
)

# 别名 -> 规范名
$script:_MCC_ALIASES = @(
    [PSCustomObject]@{ alias = 'tr';   canonical = 'agentrouter' }
    [PSCustomObject]@{ alias = 'yr';   canonical = 'anyrouter' }
    [PSCustomObject]@{ alias = 'ds';   canonical = 'deepseek' }
    [PSCustomObject]@{ alias = 'km';   canonical = 'moonshot' }
    [PSCustomObject]@{ alias = 'kimi'; canonical = 'moonshot' }
    [PSCustomObject]@{ alias = 'sf';   canonical = 'siliconflow' }
)

# --effort 合法取值（首项为默认值）
$script:_MCC_EFFORT_LEVELS = @('max', 'normal', 'min')

# 由 mcc 托管的环境变量（每次调用都会先清理，避免上一次设置残留）
$script:_MCC_MANAGED_VARS = @(
    'ANTHROPIC_MODEL'
    'ANTHROPIC_DEFAULT_OPUS_MODEL'
    'ANTHROPIC_DEFAULT_SONNET_MODEL'
    'ANTHROPIC_DEFAULT_HAIKU_MODEL'
    'ANTHROPIC_SMALL_FAST_MODEL'
    'CLAUDE_CODE_SUBAGENT_MODEL'
    'CLAUDE_CODE_EFFORT_LEVEL'
    'API_TIMEOUT_MS'
    'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC'
)

# ============================================================
# 内部工具函数
# ============================================================

# 输出错误（红色高亮）
# 用 Write-Host 而非 [Console]::Error.WriteLine：
#   - 后者直接写 .NET stderr，PowerShell 流重定向 (*>&1, 2>&1) 都捕获不到
#   - 前者经 PowerShell information stream，既能在终端高亮，也能被脚本捕获
function _mcc_err {
    param([string]$msg)
    Write-Host -ForegroundColor Red "Error: $msg"
}

# 掩码显示 API key（仅展示前 8 位）
function _mcc_mask {
    param([string]$key)
    if ($key.Length -le 8) {
        return "${key}****"
    }
    return ($key.Substring(0, 8) + '****')
}

# 若指定的环境变量已被赋值，返回 "  (from $VAR)" 标记
function _mcc_origin {
    param([string]$varname)
    $val = [Environment]::GetEnvironmentVariable($varname)
    if (-not [string]::IsNullOrEmpty($val)) {
        return "  (from `$$varname)"
    }
    return ''
}

# 别名解析：传入 alias 则回显规范名，否则原样回显
function _mcc_resolve_alias {
    param([string]$name)
    $matched = @($script:_MCC_ALIASES | Where-Object { $_.alias -eq $name })
    if ($matched.Count -gt 0) {
        return $matched[0].canonical
    }
    return $name
}

# 检查 provider 是否存在（仅检查规范名，需先 _mcc_resolve_alias）
function _mcc_provider_exists {
    param([string]$name)
    $matched = @($script:_MCC_PROVIDERS | Where-Object { $_.name -eq $name })
    return ($matched.Count -gt 0)
}

# 获取 provider 配置（含 big_model_env / small_model_env 派生字段）
function _mcc_get_config {
    param([string]$name)
    $p = $script:_MCC_PROVIDERS | Where-Object { $_.name -eq $name } | Select-Object -First 1
    $prefix = $p.api_key_env -replace '_API_KEY$', ''
    return [PSCustomObject]@{
        name            = $p.name
        default_url     = $p.default_url
        api_key_env     = $p.api_key_env
        base_url_env    = $p.base_url_env
        big_model       = $p.big_model
        small_model     = $p.small_model
        big_model_env   = "${prefix}_BIG_MODEL"
        small_model_env = "${prefix}_SMALL_MODEL"
    }
}

# 计算运行时的 URL / big_model / small_model
# 输入：来自 _mcc_get_config 的配置对象
# 规则：
#   url   <- $env:<base_url_env>    >> $cfg.default_url
#   big   <- $env:<big_model_env>   >> $cfg.big_model
#   small <- $env:<small_model_env> >> $cfg.small_model
#   big / small 互补：任一为空时复用另一个（两个都空则保持空，透传代理场景）
function _mcc_resolve_runtime {
    param($cfg)
    $env_url   = [Environment]::GetEnvironmentVariable($cfg.base_url_env)
    $env_big   = [Environment]::GetEnvironmentVariable($cfg.big_model_env)
    $env_small = [Environment]::GetEnvironmentVariable($cfg.small_model_env)

    $url       = if (-not [string]::IsNullOrEmpty($env_url))   { $env_url }   else { $cfg.default_url }
    $raw_big   = if (-not [string]::IsNullOrEmpty($env_big))   { $env_big }   else { $cfg.big_model }
    $raw_small = if (-not [string]::IsNullOrEmpty($env_small)) { $env_small } else { $cfg.small_model }

    $big   = if ([string]::IsNullOrEmpty($raw_big))   { $raw_small } else { $raw_big }
    $small = if ([string]::IsNullOrEmpty($raw_small)) { $big }       else { $raw_small }

    return [PSCustomObject]@{
        url         = $url
        big_model   = $big
        small_model = $small
    }
}

# 打印供应商列表及用法说明
function _mcc_list {
    Write-Host 'Providers:'
    Write-Host '----------'
    $sorted = $script:_MCC_PROVIDERS | Sort-Object name
    foreach ($p in $sorted) {
        $aliases = @($script:_MCC_ALIASES | Where-Object { $_.canonical -eq $p.name } | ForEach-Object { $_.alias })
        $display = if ($aliases.Count -gt 0) {
            "$($p.name) ($($aliases -join ', '))"
        } else {
            $p.name
        }

        $cfg = _mcc_get_config $p.name
        $rt = _mcc_resolve_runtime $cfg
        $from_env = _mcc_origin $cfg.base_url_env

        $model_info = ''
        if (-not [string]::IsNullOrEmpty($rt.big_model)) {
            $head = '  big=' + $rt.big_model + (_mcc_origin $cfg.big_model_env)
            $env_small_val = [Environment]::GetEnvironmentVariable($cfg.small_model_env)
            $env_small_set = -not [string]::IsNullOrEmpty($env_small_val)
            if ($rt.small_model -ne $rt.big_model -or $env_small_set) {
                $model_info = $head + ' / small=' + $rt.small_model + (_mcc_origin $cfg.small_model_env)
            } else {
                $model_info = $head
            }
        }

        $padded = $display.PadRight(20)
        Write-Host ('  ' + $padded + ' ' + $rt.url + $from_env + $model_info)
    }

    Write-Host ''
    Write-Host 'Usage:'
    Write-Host '  mcc <provider> [key_suffix] [-r|--resume] [-m|--model <model>] [-e|--effort max|normal|min]'
    Write-Host '  mcc -l|--list'
    Write-Host '  mcc -h|--help'
    Write-Host ''
    Write-Host 'Examples:'
    Write-Host '  mcc tr                              # 默认 key'
    Write-Host '  mcc yr 5433                         # ANYROUTER_API_KEY_5433'
    Write-Host '  mcc ds -m deepseek-v4-pro[1m]       # 覆盖模型（big + small 均设为该值）'
    Write-Host '  mcc ds -e normal                    # 指定 effort level'
    Write-Host '  mcc kimi 1234 --resume              # 带 key 后缀 + 恢复会话'
    Write-Host ''
    Write-Host "Override base URL / model (env var prefix matches the provider's *_API_KEY):"
    Write-Host "  `$env:DEEPSEEK_BASE_URL    = 'https://custom.host'"
    Write-Host "  `$env:DEEPSEEK_BIG_MODEL   = 'custom-pro'"
    Write-Host "  `$env:DEEPSEEK_SMALL_MODEL = 'custom-flash'"
    Write-Host ''
    Write-Host 'Model env vars applied (when model is configured):'
    Write-Host '  ANTHROPIC_MODEL'
    Write-Host '  ANTHROPIC_DEFAULT_OPUS_MODEL   <- big_model'
    Write-Host '  ANTHROPIC_DEFAULT_SONNET_MODEL <- big_model'
    Write-Host '  ANTHROPIC_DEFAULT_HAIKU_MODEL  <- small_model'
    Write-Host '  CLAUDE_CODE_SUBAGENT_MODEL     <- small_model'
    Write-Host '  CLAUDE_CODE_EFFORT_LEVEL       <- max (default) | normal | min'
    Write-Host ''
    Write-Host "Run 'mcc -h' for full help with all scenarios and caveats."
}

# 打印完整帮助
function _mcc_help {
    Write-Host @'
mcc - Claude Code 多供应商切换工具 (PowerShell)

SYNOPSIS
  mcc <provider> [key_suffix] [-r|--resume] [-m|--model <model>] [-e|--effort <level>]
  mcc -l | --list                   显示供应商表
  mcc -h | --help                   显示本帮助

ARGUMENTS
  <provider>                        供应商规范名或别名（运行 mcc -l 查看完整列表）
  [key_suffix]                      可选，API key 后缀；将选用 <PREFIX>_API_KEY_<suffix>

OPTIONS
  -r, --resume                      恢复上次会话（向 claude 传 --resume）
  -m, --model <model>               临时覆盖 big & small model（同时生效，仅本次）
  -e, --effort <max|normal|min>     设置努力等级（默认 max）
  -l, --list                        显示供应商表
  -h, --help                        显示本帮助

ENVIRONMENT VARIABLES
  约定：<PREFIX> 为 *_API_KEY 中 _API_KEY 之前的部分（如 DEEPSEEK_API_KEY -> DEEPSEEK）。

  $env:<PREFIX>_API_KEY             必填，主 API key
  $env:<PREFIX>_API_KEY_<suffix>    可选，备用 key（通过 [key_suffix] 选择）
  $env:<PREFIX>_BASE_URL            可选，覆盖配置的默认 URL
  $env:<PREFIX>_BIG_MODEL           可选，覆盖配置的默认 big model
  $env:<PREFIX>_SMALL_MODEL         可选，覆盖配置的默认 small model

PRIORITY
  模型:    -m  >  $env:<PREFIX>_BIG/SMALL_MODEL  >  供应商配置默认值
  URL:     $env:<PREFIX>_BASE_URL                >  供应商配置默认值
  API key: 由 [key_suffix] 选定具体的 KEY 变量

SCENARIOS (参数顺序任意，可自由组合)

  # 1) 基础调用（默认 key + 默认 URL + 默认模型）
  mcc deepseek
  mcc ds                            # 别名等价 mcc deepseek

  # 2) 多账号切换：备用 key
  mcc yr 5433                       # 用 $env:ANYROUTER_API_KEY_5433
  mcc deepseek work                 # 用 $env:DEEPSEEK_API_KEY_work

  # 3) 恢复上次会话
  mcc ds -r
  mcc ds --resume

  # 4) 临时换模型（仅本次有效）
  mcc ds -m deepseek-v4-pro[1m]     # big + small 都设为该值

  # 5) 调整努力等级
  mcc ds -e normal                  # max | normal | min（默认 max）
  mcc ds -e min

  # 6) 持久化覆盖模型（影响所有 mcc ds 调用）
  $env:DEEPSEEK_BIG_MODEL   = "my-pro"      # PowerShell: $env:<NAME> = "value"
  $env:DEEPSEEK_SMALL_MODEL = "my-flash"
  mcc ds

  # 7) 透传代理启用模型（agentrouter / anyrouter 默认无模型配置）
  $env:AGENTROUTER_BIG_MODEL = "foo"
  mcc tr                            # big=foo，small 回退至 foo

  # 8) 自定义 URL（自建代理或私有部署）
  $env:DEEPSEEK_BASE_URL = "https://my-proxy.example.com"
  mcc ds

  # 9) 组合：suffix + resume + 临时模型 + 努力等级
  mcc ds 5433 --resume -m custom-model -e min

  # 10) 仅命令行覆盖一边：通过环境变量分别控制
  $env:DEEPSEEK_BIG_MODEL = "big-only"
  mcc ds                            # small 走配置默认值 deepseek-v4-flash

NOTES
  - -m 同时覆盖 big & small；若需分别控制请改用 <PREFIX>_BIG_MODEL / <PREFIX>_SMALL_MODEL
  - 优先级是 CLI > 环境变量 > 配置默认；启动摘要中的 (from $VAR) 标记表示该值来自环境覆盖
  - 透传代理（agentrouter / anyrouter）配置中无模型，需 -m 或 *_BIG_MODEL 才会导出模型变量
  - big / small 任一为空时会复用另一个，避免导出空字符串到 claude
  - CLAUDE_CODE_EFFORT_LEVEL 仅在最终有模型时才导出；纯透传代理场景下 -e 无效
  - 每次 mcc 调用会先清理之前由 mcc 设置的所有变量（见代码 $_MCC_MANAGED_VARS）
  - claude 启动时固定附加 --dangerously-skip-permissions
  - API key 在摘要中只显示前 8 位，其余以 **** 掩码，便于安全分享截屏
  - 未识别的 provider 会报错；运行 mcc -l 查看可用列表
  - PowerShell 中将本文件 dot-source 加载（. .\mcc.ps1），mcc 即可修改当前 session 的 $env:*

SEE ALSO
  mcc -l                            供应商表（含别名 / 默认 URL / 默认模型）
'@
}

# ============================================================
# 主函数
#
# PowerShell 参数绑定的两个坑：
#   1) advanced function 会自动生成公共参数（-Verbose / -ErrorAction 等），
#      其中 -ErrorAction 缩写 -E 会与我们的 -e 冲突 —— 必须用 [Alias('e')]
#      显式占位才能让 -e 精确匹配 effort。
#   2) PowerShell 不原生识别 --xxx 长选项，会把它们当作普通位置参数。
#      因此长选项一律塞进 ValueFromRemainingArguments 的 $Rest，函数内手动解析。
#
# 参数名加 Mcc 前缀是为了避免与 PowerShell 公共参数及其缩写碰撞。
# ============================================================
function mcc {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Alias('r')] [switch]$McR,
        [Alias('l')] [switch]$McL,
        [Alias('h')] [switch]$McH,
        [Alias('e')] [string]$McE,
        [Alias('m')] [string]$McM,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Rest
    )

    # --- 参数解析 ---
    $provider   = ''
    $key_suffix = ''
    $resume     = $McR.IsPresent
    $list_flag  = $McL.IsPresent
    $help_flag  = $McH.IsPresent
    $effort     = $McE
    $model      = $McM

    $positional = @()
    if ($null -ne $Rest) {
        $i = 0
        while ($i -lt $Rest.Count) {
            $a = $Rest[$i]
            switch ($a) {
                '--resume' { $resume = $true; break }
                '--list'   { $list_flag = $true; break }
                '--help'   { $help_flag = $true; break }
                '--model'  { $i++; $model = $Rest[$i]; break }
                '--effort' { $i++; $effort = $Rest[$i]; break }
                default    { $positional += $a }
            }
            $i++
        }
    }

    if ($positional.Count -ge 1) { $provider   = $positional[0] }
    if ($positional.Count -ge 2) { $key_suffix = $positional[1] }

    if ($list_flag) { _mcc_list; return }
    if ($help_flag) { _mcc_help; return }

    if ([string]::IsNullOrEmpty($provider)) {
        _mcc_err 'provider required'
        Write-Host ''
        _mcc_list
        return
    }

    if ((-not [string]::IsNullOrEmpty($effort)) -and ($effort -notin $script:_MCC_EFFORT_LEVELS)) {
        _mcc_err "--effort must be one of: $($script:_MCC_EFFORT_LEVELS -join ' ')"
        return
    }

    $canon = _mcc_resolve_alias $provider
    if (-not (_mcc_provider_exists $canon)) {
        _mcc_err "unknown provider '$provider'"
        Write-Host "       Run 'mcc --list' to see available providers."
        return
    }

    $cfg = _mcc_get_config $canon

    # 确定 API key
    $key_var = if (-not [string]::IsNullOrEmpty($key_suffix)) {
        $cfg.api_key_env + '_' + $key_suffix
    } else {
        $cfg.api_key_env
    }
    $api_key = [Environment]::GetEnvironmentVariable($key_var)
    if ([string]::IsNullOrEmpty($api_key)) {
        _mcc_err "'$key_var' is not set"
        Write-Host "       `$env:$key_var = 'your_api_key'"
        return
    }

    # 确定 URL / 模型（CLI -m > <PREFIX>_BIG/SMALL_MODEL > 配置默认）
    $rt = _mcc_resolve_runtime $cfg
    $base_url     = $rt.url
    $big_model    = if (-not [string]::IsNullOrEmpty($model)) { $model } else { $rt.big_model }
    $small_model  = if (-not [string]::IsNullOrEmpty($model)) { $model } else { $rt.small_model }
    $effort_level = if (-not [string]::IsNullOrEmpty($effort)) { $effort } else { $script:_MCC_EFFORT_LEVELS[0] }

    # 启动摘要
    Write-Host "Provider  : $canon"
    Write-Host ('Base URL  : ' + $base_url + (_mcc_origin $cfg.base_url_env))
    Write-Host "API Key   : $(_mcc_mask $api_key)  ($key_var)"
    if (-not [string]::IsNullOrEmpty($big_model)) {
        $big_tag   = if (-not [string]::IsNullOrEmpty($model)) { '' } else { (_mcc_origin $cfg.big_model_env) }
        $small_tag = if (-not [string]::IsNullOrEmpty($model)) { '' } else { (_mcc_origin $cfg.small_model_env) }
        Write-Host ('Big Model : ' + $big_model + $big_tag)
        Write-Host ('Sm Model  : ' + $small_model + $small_tag)
        Write-Host "Effort    : $effort_level"
    }
    if ($resume) { Write-Host 'Mode      : resume' }
    Write-Host ''

    # 清理之前 mcc 设置的环境变量
    foreach ($v in $script:_MCC_MANAGED_VARS) {
        Remove-Item -Path "Env:$v" -ErrorAction SilentlyContinue
    }

    # 设置新环境变量
    $env:ANTHROPIC_BASE_URL   = $base_url
    $env:ANTHROPIC_AUTH_TOKEN = $api_key

    if (-not [string]::IsNullOrEmpty($big_model)) {
        $env:ANTHROPIC_MODEL                          = $big_model
        $env:ANTHROPIC_DEFAULT_OPUS_MODEL             = $big_model
        $env:ANTHROPIC_DEFAULT_SONNET_MODEL           = $big_model
        $env:ANTHROPIC_DEFAULT_HAIKU_MODEL            = $small_model
        $env:CLAUDE_CODE_SUBAGENT_MODEL               = $small_model
        $env:CLAUDE_CODE_EFFORT_LEVEL                 = $effort_level
        $env:API_TIMEOUT_MS                           = '600000'
        $env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = '1'
    }

    # 启动 claude（@ 是 PowerShell splatting 运算符，把数组展开为参数）
    # 注意：用 += 累积而非 `if/else` 表达式赋值——后者会让单元素数组被 unwrap 成字符串，
    # 导致 splatting 时按 IEnumerable<char> 拆字符传给 claude。
    $claude_args = @('--dangerously-skip-permissions')
    if ($resume) { $claude_args += '--resume' }
    & claude @claude_args
}

# ============================================================
# 补全（Register-ArgumentCompleter）
#
# 动态读取 $_MCC_PROVIDERS / $_MCC_ALIASES / 当前 env，与 nushell 版本逻辑等价。
# 注册两处：
#   1) -ParameterName McE  ->  -e <TAB> 直接给 effort 候选
#   2) -ParameterName Rest ->  位置参数 + --effort/--model 后值的统一补全入口
# ============================================================
Register-ArgumentCompleter -CommandName mcc -ParameterName McE -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    @($script:_MCC_EFFORT_LEVELS |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        })
}

Register-ArgumentCompleter -CommandName mcc -ParameterName Rest -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # 提取所有已输入 token（含命令名 mcc）
    $elements = @($commandAst.CommandElements | ForEach-Object { $_.ToString() })
    # 排除命令名
    $tokens = if ($elements.Count -gt 1) { @($elements[1..($elements.Count - 1)]) } else { @() }

    # 区分"光标正在输入的部分单词"和"已完成的 token"
    $is_completing_current = ($tokens.Count -gt 0) -and ($tokens[-1] -eq $wordToComplete)
    $completed_tokens = if ($is_completing_current) {
        if ($tokens.Count -gt 1) { @($tokens[0..($tokens.Count - 2)]) } else { @() }
    } else {
        $tokens
    }

    # 若上一个 token 是带值长选项，则补全对应取值
    $prev = if ($completed_tokens.Count -gt 0) { $completed_tokens[-1] } else { '' }
    if ($prev -eq '--effort') {
        return @($script:_MCC_EFFORT_LEVELS |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            })
    }
    if ($prev -eq '--model') {
        return @()
    }

    # 解析已完成 token，跳过长选项及其值，剩下的就是位置参数
    # 注意：-r/-l/-h/-e/-m 由 PowerShell 解析到 McR/McL/McH/McE/McM，不会进入 $commandAst 这条路径吗？
    # 实测会进 commandAst.CommandElements，但我们用作 token 序列分析时按"位置参数 vs 长选项"过滤即可。
    $positional = @()
    $skip_next = $false
    foreach ($t in $completed_tokens) {
        if ($skip_next) {
            $skip_next = $false
            continue
        }
        if ($t -in @('--model', '--effort')) {
            $skip_next = $true
            continue
        }
        if ($t -in @('-m', '-e')) {
            # 短选项带值；下一个 token 是其值，但已被 PowerShell 绑定到 McM/McE，
            # 仍然出现在 CommandElements 中，要跳过下一个 token
            $skip_next = $true
            continue
        }
        if ($t.StartsWith('-')) {
            # -r/-l/-h/--resume/--list/--help 等无值开关
            continue
        }
        $positional += $t
    }

    # 第 1 个位置参数：provider 名 + 别名
    if ($positional.Count -eq 0) {
        $candidates = @()
        $candidates += @($script:_MCC_PROVIDERS | ForEach-Object { $_.name })
        $candidates += @($script:_MCC_ALIASES   | ForEach-Object { $_.alias })
        return @($candidates |
            Where-Object { $_ -like "$wordToComplete*" } |
            Sort-Object |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            })
    }

    # 第 2 个位置参数:key_suffix（扫描已设置的 <PREFIX>_API_KEY_<suffix>）
    if ($positional.Count -eq 1) {
        $provider = $positional[0]
        $canon = _mcc_resolve_alias $provider
        if (-not (_mcc_provider_exists $canon)) { return @() }
        $cfg = _mcc_get_config $canon
        $prefix = $cfg.api_key_env + '_'
        $prefix_len = $prefix.Length
        $suffixes = @(Get-ChildItem Env: |
            Where-Object { $_.Name.StartsWith($prefix) -and ($_.Name -ne $cfg.api_key_env) } |
            ForEach-Object { $_.Name.Substring($prefix_len) })
        return @($suffixes |
            Where-Object { $_ -like "$wordToComplete*" } |
            Sort-Object |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            })
    }

    return @()
}
