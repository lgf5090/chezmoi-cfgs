#!/usr/bin/env nu

# Claude Code 多供应商切换工具（nushell 版本）
#
# 用法：
#   mcc <provider> [key_suffix] [-r|--resume] [-m|--model <model>] [-e|--effort max|normal|min]
#   mcc -l | --list                 显示供应商表
#   mcc -h | --help                 显示完整帮助（含场景示例与注意事项）
#
# 新增供应商：在 $_MCC_PROVIDERS 中添加一行即可，补全自动生效。

# ============================================================
# 供应商配置（唯一数据源）
# big_model   → ANTHROPIC_MODEL / DEFAULT_OPUS / DEFAULT_SONNET
# small_model → DEFAULT_HAIKU / CLAUDE_CODE_SUBAGENT_MODEL
# 空字符串    → 不设置模型变量（适用于透传代理）
# ============================================================
const _MCC_PROVIDERS = [
    { name: "agentrouter", default_url: "https://agentrouter.org",                api_key_env: "AGENTROUTER_API_KEY", base_url_env: "AGENTROUTER_BASE_URL", big_model: "",                            small_model: "" }
    { name: "anyrouter",   default_url: "https://anyrouter.top",                  api_key_env: "ANYROUTER_API_KEY",   base_url_env: "ANYROUTER_BASE_URL",   big_model: "",                            small_model: "" }
    { name: "deepseek",    default_url: "https://api.deepseek.com/anthropic",     api_key_env: "DEEPSEEK_API_KEY",    base_url_env: "DEEPSEEK_BASE_URL",    big_model: "deepseek-v4-pro[1m]",         small_model: "deepseek-v4-flash" }
    { name: "moonshot",    default_url: "https://api.moonshot.cn/anthropic",      api_key_env: "MOONSHOT_API_KEY",    base_url_env: "MOONSHOT_BASE_URL",    big_model: "kimi-k2.6",                   small_model: "kimi-k2.6" }
    { name: "glm",         default_url: "https://open.bigmodel.cn/api/anthropic", api_key_env: "GLM_API_KEY",         base_url_env: "GLM_BASE_URL",         big_model: "GLM-5.1",                     small_model: "GLM-5.1" }
    { name: "siliconflow", default_url: "https://api.siliconflow.cn/",            api_key_env: "SILICONFLOW_API_KEY", base_url_env: "SILICONFLOW_BASE_URL", big_model: "deepseek-ai/DeepSeek-V4-Pro", small_model: "deepseek-ai/DeepSeek-V4-Flash" }
]

# 别名 → 规范名
const _MCC_ALIASES = [
    { alias: "tr",   canonical: "agentrouter" }
    { alias: "yr",   canonical: "anyrouter" }
    { alias: "ds",   canonical: "deepseek" }
    { alias: "km",   canonical: "moonshot" }
    { alias: "kimi", canonical: "moonshot" }
    { alias: "sf",   canonical: "siliconflow" }
]

# --effort 合法取值（首项为默认值）
const _MCC_EFFORT_LEVELS = ["max" "normal" "min"]

# 由 mcc 托管的环境变量（每次调用都会先清理，避免上一次设置残留）
const _MCC_MANAGED_VARS = [
    "ANTHROPIC_MODEL"
    "ANTHROPIC_DEFAULT_OPUS_MODEL"
    "ANTHROPIC_DEFAULT_SONNET_MODEL"
    "ANTHROPIC_DEFAULT_HAIKU_MODEL"
    "ANTHROPIC_SMALL_FAST_MODEL"
    "CLAUDE_CODE_SUBAGENT_MODEL"
    "CLAUDE_CODE_EFFORT_LEVEL"
    "API_TIMEOUT_MS"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"
]

# ============================================================
# 内部工具函数
# ============================================================

# 输出错误到 stderr
def _mcc_err [msg: string] {
    print -e $"(ansi red)Error:(ansi reset) ($msg)"
}

# 掩码显示 API key（仅展示前 8 位）
def _mcc_mask [key: string] {
    if ($key | str length) <= 8 {
        $"($key)****"
    } else {
        (($key | str substring 0..7) + "****")
    }
}

# 若指定的环境变量已被赋值，返回 "  (from $VAR)" 标记
def _mcc_origin [varname: string] {
    let val = ($env | get -o $varname | default "")
    if ($val | is-not-empty) {
        "  (from $" + $varname + ")"
    } else {
        ""
    }
}

# 别名解析：传入 alias 则回显规范名，否则原样回显
def _mcc_resolve_alias [name: string] {
    let matched = ($_MCC_ALIASES | where alias == $name)
    if ($matched | is-not-empty) {
        ($matched | first | get canonical)
    } else {
        $name
    }
}

# 检查 provider 是否存在（仅检查规范名，需先 _mcc_resolve_alias）
def _mcc_provider_exists [name: string] {
    ($_MCC_PROVIDERS | where name == $name | is-not-empty)
}

# 获取 provider 配置（含 big_model_env / small_model_env 派生字段）
def _mcc_get_config [name: string] {
    let p = ($_MCC_PROVIDERS | where name == $name | first)
    let prefix = ($p.api_key_env | str replace -r '_API_KEY$' '')
    {
        name:            $p.name
        default_url:     $p.default_url
        api_key_env:     $p.api_key_env
        base_url_env:    $p.base_url_env
        big_model:       $p.big_model
        small_model:     $p.small_model
        big_model_env:   ($prefix + "_BIG_MODEL")
        small_model_env: ($prefix + "_SMALL_MODEL")
    }
}

# 计算运行时的 URL / big_model / small_model
# 输入：来自 _mcc_get_config 的配置记录
# 规则：
#   url   ← $env.<base_url_env>   ≫ $cfg.default_url
#   big   ← $env.<big_model_env>  ≫ $cfg.big_model
#   small ← $env.<small_model_env> ≫ $cfg.small_model
#   big / small 互补：任一为空时复用另一个（两个都空则保持空，透传代理场景）
# 返回：{ url, big_model, small_model } 记录
def _mcc_resolve_runtime [cfg: record] {
    let env_url = ($env | get -o $cfg.base_url_env | default "")
    let env_big = ($env | get -o $cfg.big_model_env | default "")
    let env_small = ($env | get -o $cfg.small_model_env | default "")

    let url = if ($env_url | is-not-empty) { $env_url } else { $cfg.default_url }
    let raw_big = if ($env_big | is-not-empty) { $env_big } else { $cfg.big_model }
    let raw_small = if ($env_small | is-not-empty) { $env_small } else { $cfg.small_model }

    let big = if ($raw_big | is-empty) { $raw_small } else { $raw_big }
    let small = if ($raw_small | is-empty) { $big } else { $raw_small }

    { url: $url, big_model: $big, small_model: $small }
}

# 打印供应商列表及用法说明
def _mcc_list [] {
    print "Providers:"
    print "----------"
    for p in ($_MCC_PROVIDERS | sort-by name) {
        let aliases = ($_MCC_ALIASES | where canonical == $p.name | get alias)
        let display = if ($aliases | is-not-empty) {
            $p.name + " (" + ($aliases | str join ", ") + ")"
        } else {
            $p.name
        }

        let cfg = (_mcc_get_config $p.name)
        let rt = (_mcc_resolve_runtime $cfg)
        let from_env = (_mcc_origin $cfg.base_url_env)

        let model_info = (
            if ($rt.big_model | is-not-empty) {
                let head = "  big=" + $rt.big_model + (_mcc_origin $cfg.big_model_env)
                let env_small_set = (($env | get -o $cfg.small_model_env | default "") | is-not-empty)
                if $rt.small_model != $rt.big_model or $env_small_set {
                    $head + " / small=" + $rt.small_model + (_mcc_origin $cfg.small_model_env)
                } else {
                    $head
                }
            } else {
                ""
            }
        )

        print ("  " + ($display | fill -a l -w 20) + " " + $rt.url + $from_env + $model_info)
    }

    print ""
    print "Usage:"
    print "  mcc <provider> [key_suffix] [-r|--resume] [-m|--model <model>] [-e|--effort max|normal|min]"
    print "  mcc -l|--list"
    print "  mcc -h|--help"
    print ""
    print "Examples:"
    print "  mcc tr                              # 默认 key"
    print "  mcc yr 5433                         # ANYROUTER_API_KEY_5433"
    print "  mcc ds -m deepseek-v4-pro[1m]       # 覆盖模型（big + small 均设为该值）"
    print "  mcc ds -e normal                    # 指定 effort level"
    print "  mcc kimi 1234 --resume              # 带 key 后缀 + 恢复会话"
    print ""
    print "Override base URL / model (env var prefix matches the provider's *_API_KEY):"
    print "  $env.DEEPSEEK_BASE_URL   = 'https://custom.host'"
    print "  $env.DEEPSEEK_BIG_MODEL  = 'custom-pro'"
    print "  $env.DEEPSEEK_SMALL_MODEL = 'custom-flash'"
    print ""
    print "Model env vars applied (when model is configured):"
    print "  ANTHROPIC_MODEL"
    print "  ANTHROPIC_DEFAULT_OPUS_MODEL   ← big_model"
    print "  ANTHROPIC_DEFAULT_SONNET_MODEL ← big_model"
    print "  ANTHROPIC_DEFAULT_HAIKU_MODEL  ← small_model"
    print "  CLAUDE_CODE_SUBAGENT_MODEL     ← small_model"
    print "  CLAUDE_CODE_EFFORT_LEVEL       ← max (default) | normal | min"
    print ""
    print "Run 'mcc -h' for full help with all scenarios and caveats."
}

# 打印完整帮助
def _mcc_help [] {
    print 'mcc - Claude Code 多供应商切换工具 (nushell)

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
  约定：<PREFIX> 为 *_API_KEY 中 _API_KEY 之前的部分（如 DEEPSEEK_API_KEY → DEEPSEEK）。

  $env.<PREFIX>_API_KEY             必填，主 API key
  $env.<PREFIX>_API_KEY_<suffix>    可选，备用 key（通过 [key_suffix] 选择）
  $env.<PREFIX>_BASE_URL            可选，覆盖配置的默认 URL
  $env.<PREFIX>_BIG_MODEL           可选，覆盖配置的默认 big model
  $env.<PREFIX>_SMALL_MODEL         可选，覆盖配置的默认 small model

PRIORITY
  模型:    -m  >  $env.<PREFIX>_BIG/SMALL_MODEL  >  供应商配置默认值
  URL:     $env.<PREFIX>_BASE_URL                >  供应商配置默认值
  API key: 由 [key_suffix] 选定具体的 KEY 变量

SCENARIOS (参数顺序任意，可自由组合)

  # 1) 基础调用（默认 key + 默认 URL + 默认模型）
  mcc deepseek
  mcc ds                            # 别名等价 mcc deepseek

  # 2) 多账号切换：备用 key
  mcc yr 5433                       # 用 $env.ANYROUTER_API_KEY_5433
  mcc deepseek work                 # 用 $env.DEEPSEEK_API_KEY_work

  # 3) 恢复上次会话
  mcc ds -r
  mcc ds --resume

  # 4) 临时换模型（仅本次有效）
  mcc ds -m deepseek-v4-pro[1m]     # big + small 都设为该值

  # 5) 调整努力等级
  mcc ds -e normal                  # max | normal | min（默认 max）
  mcc ds -e min

  # 6) 持久化覆盖模型（影响所有 mcc ds 调用）
  $env.DEEPSEEK_BIG_MODEL = "my-pro"     # nushell: 直接赋值 $env.<NAME>
  $env.DEEPSEEK_SMALL_MODEL = "my-flash"
  mcc ds

  # 7) 透传代理启用模型（agentrouter / anyrouter 默认无模型配置）
  $env.AGENTROUTER_BIG_MODEL = "foo"
  mcc tr                            # big=foo，small 回退至 foo

  # 8) 自定义 URL（自建代理或私有部署）
  $env.DEEPSEEK_BASE_URL = "https://my-proxy.example.com"
  mcc ds

  # 9) 组合：suffix + resume + 临时模型 + 努力等级
  mcc ds 5433 --resume -m custom-model -e min

  # 10) 仅命令行覆盖一边：通过环境变量分别控制
  $env.DEEPSEEK_BIG_MODEL = "big-only"
  mcc ds                            # small 走配置默认值 deepseek-v4-flash

NOTES
  · -m 同时覆盖 big & small；若需分别控制请改用 <PREFIX>_BIG_MODEL / <PREFIX>_SMALL_MODEL
  · 优先级是 CLI > 环境变量 > 配置默认；启动摘要中的 (from $VAR) 标记表示该值来自环境覆盖
  · 透传代理（agentrouter / anyrouter）配置中无模型，需 -m 或 *_BIG_MODEL 才会导出模型变量
  · big / small 任一为空时会复用另一个，避免导出空字符串到 claude
  · CLAUDE_CODE_EFFORT_LEVEL 仅在最终有模型时才导出；纯透传代理场景下 -e 无效
  · 每次 mcc 调用会先 unset 之前由 mcc 设置的所有变量（见代码 $_MCC_MANAGED_VARS）
  · claude 启动时固定附加 --dangerously-skip-permissions
  · API key 在摘要中只显示前 8 位，其余以 **** 掩码，便于安全分享截屏
  · 未识别的 provider 会报错；运行 mcc -l 查看可用列表
  · nushell 中 mcc 必须以 `def --env` 实现，否则 $env 修改不会传递回交互 shell

SEE ALSO
  mcc -l                            供应商表（含别名 / 默认 URL / 默认模型）'
}

# ============================================================
# nushell 补全（动态读取 $_MCC_PROVIDERS / $_MCC_ALIASES）
# ============================================================

# provider 候选：规范名 + 别名
def "nu-complete _mcc_provider" [] {
    let names = ($_MCC_PROVIDERS | get name)
    let aliases = ($_MCC_ALIASES | get alias)
    $names ++ $aliases
}

# effort 候选
def "nu-complete _mcc_effort" [] {
    $_MCC_EFFORT_LEVELS
}

# key_suffix 候选：扫描已设置的 <PREFIX>_API_KEY_<suffix> 环境变量
# fish 等价物用 commandline -opc 获取已输入的 tokens，nushell 这里用补全器
# 接收的 $context 参数（光标前的命令行字符串）做同样的解析。
def "nu-complete _mcc_key_suffix" [context: string] {
    let tokens = ($context | str trim | split row -r '\s+')
    let rest = ($tokens | skip 1)
    let parsed = (
        $rest
        | reduce -f { positional: [], skip_next: false } { |token, acc|
            if $acc.skip_next {
                { positional: $acc.positional, skip_next: false }
            } else if $token in ["-m" "--model" "-e" "--effort"] {
                { positional: $acc.positional, skip_next: true }
            } else if ($token | str starts-with "-") {
                $acc
            } else {
                { positional: ($acc.positional | append $token), skip_next: false }
            }
        }
    )
    if ($parsed.positional | is-empty) { return [] }
    let provider = ($parsed.positional | first)
    let canon = (_mcc_resolve_alias $provider)
    if not (_mcc_provider_exists $canon) { return [] }
    let cfg = (_mcc_get_config $canon)
    let prefix = ($cfg.api_key_env + "_")
    let prefix_len = ($prefix | str length)
    $env
    | columns
    | where { |x| ($x | str starts-with $prefix) and ($x != $cfg.api_key_env) }
    | each { |x| $x | str substring $prefix_len.. }
}

# ============================================================
# 主函数
# ============================================================
def --env mcc [
    provider?: string@"nu-complete _mcc_provider"      # 供应商规范名或别名
    key_suffix?: string@"nu-complete _mcc_key_suffix"  # API key 后缀
    --resume(-r)                                       # 恢复上次会话
    --model(-m): string                                # 临时覆盖 big & small model
    --effort(-e): string@"nu-complete _mcc_effort"     # 努力等级 (max|normal|min)
    --list(-l)                                         # 显示供应商表
    --help(-h)                                         # 显示完整帮助
] {
    if $list { _mcc_list; return }
    if $help { _mcc_help; return }

    if ($provider | is-empty) {
        _mcc_err "provider required"
        print ""
        _mcc_list
        return
    }

    if ($effort | is-not-empty) and ($effort not-in $_MCC_EFFORT_LEVELS) {
        _mcc_err $"--effort must be one of: ($_MCC_EFFORT_LEVELS | str join ' ')"
        return
    }

    let canon = (_mcc_resolve_alias $provider)
    if not (_mcc_provider_exists $canon) {
        _mcc_err $"unknown provider '($provider)'"
        print -e "       Run 'mcc --list' to see available providers."
        return
    }

    let cfg = (_mcc_get_config $canon)

    # 确定 API key
    let key_var = if ($key_suffix | is-not-empty) {
        $cfg.api_key_env + "_" + $key_suffix
    } else {
        $cfg.api_key_env
    }
    let api_key = ($env | get -o $key_var | default "")
    if ($api_key | is-empty) {
        _mcc_err $"'($key_var)' is not set"
        print -e $"       $env.($key_var) = 'your_api_key'"
        return
    }

    # 确定 URL / 模型（CLI -m > <PREFIX>_BIG/SMALL_MODEL > 配置默认）
    let rt = (_mcc_resolve_runtime $cfg)
    let base_url = $rt.url
    let big_model = if ($model | is-not-empty) { $model } else { $rt.big_model }
    let small_model = if ($model | is-not-empty) { $model } else { $rt.small_model }

    # 启动摘要
    print $"Provider  : ($canon)"
    print ("Base URL  : " + $base_url + (_mcc_origin $cfg.base_url_env))
    print $"API Key   : (_mcc_mask $api_key)  \(($key_var)\)"
    if ($big_model | is-not-empty) {
        let big_tag = if ($model | is-not-empty) { "" } else { (_mcc_origin $cfg.big_model_env) }
        let small_tag = if ($model | is-not-empty) { "" } else { (_mcc_origin $cfg.small_model_env) }
        print ("Big Model : " + $big_model + $big_tag)
        print ("Sm Model  : " + $small_model + $small_tag)
        let effort_level = if ($effort | is-not-empty) { $effort } else { ($_MCC_EFFORT_LEVELS | first) }
        print $"Effort    : ($effort_level)"
    }
    if $resume { print "Mode      : resume" }
    print ""

    # 清理之前 mcc 设置的环境变量
    hide-env --ignore-errors ...$_MCC_MANAGED_VARS

    # 设置新环境变量
    $env.ANTHROPIC_BASE_URL = $base_url
    $env.ANTHROPIC_AUTH_TOKEN = $api_key

    if ($big_model | is-not-empty) {
        $env.ANTHROPIC_MODEL = $big_model
        $env.ANTHROPIC_DEFAULT_OPUS_MODEL = $big_model
        $env.ANTHROPIC_DEFAULT_SONNET_MODEL = $big_model
        $env.ANTHROPIC_DEFAULT_HAIKU_MODEL = $small_model
        $env.CLAUDE_CODE_SUBAGENT_MODEL = $small_model
        $env.CLAUDE_CODE_EFFORT_LEVEL = (if ($effort | is-not-empty) { $effort } else { ($_MCC_EFFORT_LEVELS | first) })
        $env.API_TIMEOUT_MS = "600000"
        $env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
    }

    # 启动 claude
    let claude_args = if $resume {
        ["--dangerously-skip-permissions" "--resume"]
    } else {
        ["--dangerously-skip-permissions"]
    }
    ^claude ...$claude_args
}
