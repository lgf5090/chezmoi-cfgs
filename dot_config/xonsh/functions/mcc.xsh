import subprocess
import sys

from xonsh.built_ins import XSH

_MCC_PROVIDERS = {
    "agentrouter": ("https://agentrouter.org", "AGENTROUTER_API_KEY", "AGENTROUTER_BASE_URL", "", ""),
    "anyrouter": ("https://anyrouter.top", "ANYROUTER_API_KEY", "ANYROUTER_BASE_URL", "", ""),
    "deepseek": (
        "https://api.deepseek.com/anthropic",
        "DEEPSEEK_API_KEY",
        "DEEPSEEK_BASE_URL",
        "deepseek-v4-pro[1m]",
        "deepseek-v4-flash",
    ),
    "moonshot": ("https://api.moonshot.cn/anthropic", "MOONSHOT_API_KEY", "MOONSHOT_BASE_URL", "kimi-k2.6", "kimi-k2.6"),
    "glm": ("https://open.bigmodel.cn/api/anthropic", "GLM_API_KEY", "GLM_BASE_URL", "GLM-5.1", "GLM-5.1"),
    "siliconflow": (
        "https://api.siliconflow.cn/",
        "SILICONFLOW_API_KEY",
        "SILICONFLOW_BASE_URL",
        "deepseek-ai/DeepSeek-V4-Pro",
        "deepseek-ai/DeepSeek-V4-Flash",
    ),
}

_MCC_ALIASES = {
    "tr": "agentrouter",
    "yr": "anyrouter",
    "ds": "deepseek",
    "km": "moonshot",
    "kimi": "moonshot",
    "sf": "siliconflow",
}

_MCC_EFFORT_LEVELS = ["max", "normal", "min"]
_MCC_MANAGED_VARS = [
    "ANTHROPIC_MODEL",
    "ANTHROPIC_DEFAULT_OPUS_MODEL",
    "ANTHROPIC_DEFAULT_SONNET_MODEL",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL",
    "ANTHROPIC_SMALL_FAST_MODEL",
    "CLAUDE_CODE_SUBAGENT_MODEL",
    "CLAUDE_CODE_EFFORT_LEVEL",
    "API_TIMEOUT_MS",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC",
]


def _mcc_env(name, default=""):
    value = XSH.env.get(name)
    return str(value) if value is not None else default


def _mcc_parse_config(provider):
    default_url, key_env, url_env, big_model, small_model = _MCC_PROVIDERS[provider]
    prefix = key_env.removesuffix("_API_KEY")
    return {
        "default_url": default_url,
        "key_env": key_env,
        "url_env": url_env,
        "big_model": big_model,
        "small_model": small_model,
        "big_model_env": f"{prefix}_BIG_MODEL",
        "small_model_env": f"{prefix}_SMALL_MODEL",
    }


def _mcc_err(message):
    print(f"Error: {message}", file=sys.stderr)


def _mcc_origin(name):
    return f"  (from ${name})" if _mcc_env(name) else ""


def _mcc_mask(value):
    return f"{value[:8]}****"


def _mcc_list():
    print("Providers:")
    print("----------")
    for provider in sorted(_MCC_PROVIDERS):
        config = _mcc_parse_config(provider)
        provider_aliases = [alias for alias, target in sorted(_MCC_ALIASES.items()) if target == provider]
        display = provider
        if provider_aliases:
            display += f" ({', '.join(provider_aliases)})"

        url = _mcc_env(config["url_env"], config["default_url"]) or config["default_url"]
        cfg_big = _mcc_env(config["big_model_env"], config["big_model"]) or config["big_model"]
        cfg_small = _mcc_env(config["small_model_env"], config["small_model"]) or config["small_model"]
        model_info = ""
        if cfg_big or cfg_small:
            cfg_big = cfg_big or cfg_small
            cfg_small = cfg_small or cfg_big
            model_info = f"  big={cfg_big}{_mcc_origin(config['big_model_env'])}"
            if cfg_small != cfg_big or _mcc_env(config["small_model_env"]):
                model_info += f" / small={cfg_small}{_mcc_origin(config['small_model_env'])}"
        print(f"  {display:<20} {url}{_mcc_origin(config['url_env'])}{model_info}")

    print(
        """
Usage:
  mcc <provider> [key_suffix] [-r|--resume] [-m|--model <model>] [-e|--effort max|normal|min]
  mcc -l|--list
  mcc -h|--help

Examples:
  mcc tr                              # 默认 key
  mcc yr 5433                         # ANYROUTER_API_KEY_5433
  mcc ds -m deepseek-v4-pro[1m]      # 覆盖模型（big + small 均设为该值）
  mcc ds -e normal                    # 指定 effort level
  mcc kimi 1234 --resume              # 带 key 后缀 + 恢复会话

Override base URL / model (env var prefix matches the provider's *_API_KEY):
  export DEEPSEEK_BASE_URL='https://custom.host'
  export DEEPSEEK_BIG_MODEL='custom-pro'
  export DEEPSEEK_SMALL_MODEL='custom-flash'

Model env vars applied (when model is configured):
  ANTHROPIC_MODEL
  ANTHROPIC_DEFAULT_OPUS_MODEL   ← big_model
  ANTHROPIC_DEFAULT_SONNET_MODEL ← big_model
  ANTHROPIC_DEFAULT_HAIKU_MODEL  ← small_model
  CLAUDE_CODE_SUBAGENT_MODEL     ← small_model
  CLAUDE_CODE_EFFORT_LEVEL       ← max (default) | normal | min

Run 'mcc -h' for full help with all scenarios and caveats.
""".strip()
    )


def _mcc_help():
    print(
        """
mcc - Claude Code 多供应商切换工具

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

  <PREFIX>_API_KEY                  必填，主 API key
  <PREFIX>_API_KEY_<suffix>         可选，备用 key（通过 [key_suffix] 选择）
  <PREFIX>_BASE_URL                 可选，覆盖配置的默认 URL
  <PREFIX>_BIG_MODEL                可选，覆盖配置的默认 big model
  <PREFIX>_SMALL_MODEL              可选，覆盖配置的默认 small model

PRIORITY
  模型:    -m  >  <PREFIX>_BIG/SMALL_MODEL  >  供应商配置默认值
  URL:     <PREFIX>_BASE_URL                >  供应商配置默认值
  API key: 由 [key_suffix] 选定具体的 KEY 变量

SCENARIOS (参数顺序任意，可自由组合)

  # 1) 基础调用（默认 key + 默认 URL + 默认模型）
  mcc deepseek
  mcc ds                            # 别名等价 mcc deepseek

  # 2) 多账号切换：备用 key
  mcc yr 5433                       # 用 ANYROUTER_API_KEY_5433
  mcc deepseek work                 # 用 DEEPSEEK_API_KEY_work

  # 3) 恢复上次会话
  mcc ds -r
  mcc ds --resume

  # 4) 临时换模型（仅本次有效）
  mcc ds -m deepseek-v4-pro[1m]     # big + small 都设为该值

  # 5) 调整努力等级
  mcc ds -e normal                  # max | normal | min（默认 max）
  mcc ds -e min

  # 6) 持久化覆盖模型（影响所有 mcc ds 调用）
  export DEEPSEEK_BIG_MODEL=my-pro
  export DEEPSEEK_SMALL_MODEL=my-flash
  mcc ds

  # 7) 透传代理启用模型（agentrouter / anyrouter 默认无模型配置）
  export AGENTROUTER_BIG_MODEL=foo
  mcc tr                            # big=foo，small 回退至 foo

  # 8) 自定义 URL（自建代理或私有部署）
  export DEEPSEEK_BASE_URL=https://my-proxy.example.com
  mcc ds

  # 9) 组合：suffix + resume + 临时模型 + 努力等级
  mcc ds 5433 --resume -m custom-model -e min

  # 10) 仅命令行覆盖一边：通过环境变量分别控制
  export DEEPSEEK_BIG_MODEL=big-only
  mcc ds                            # small 走配置默认值 deepseek-v4-flash

NOTES
  · -m 同时覆盖 big & small；若需分别控制请改用 <PREFIX>_BIG_MODEL / <PREFIX>_SMALL_MODEL
  · 优先级是 CLI > 环境变量 > 配置默认；启动摘要中的 (from $VAR) 标记表示该值来自环境覆盖
  · 透传代理（agentrouter / anyrouter）配置中无模型，需 -m 或 *_BIG_MODEL 才会导出模型变量
  · big / small 任一为空时会复用另一个，避免导出空字符串到 claude
  · CLAUDE_CODE_EFFORT_LEVEL 仅在最终有模型时才导出；纯透传代理场景下 -e 无效
  · 每次 mcc 调用会先 unset 之前由 mcc 设置的所有变量（见代码 _MCC_MANAGED_VARS）
  · claude 启动时固定附加 --dangerously-skip-permissions
  · API key 在摘要中只显示前 8 位，其余以 **** 掩码，便于安全分享截屏
  · 未识别的 provider 会报错；运行 mcc -l 查看可用列表

SEE ALSO
  mcc -l                            供应商表（含别名 / 默认 URL / 默认模型）
""".strip()
    )


def _mcc(args, stdin=None):
    if not args:
        _mcc_err("provider required")
        print()
        _mcc_list()
        return 1

    if args[0] in ("-l", "--list"):
        _mcc_list()
        return 0

    if args[0] in ("-h", "--help"):
        _mcc_help()
        return 0

    provider = _MCC_ALIASES.get(args[0], args[0])
    if provider not in _MCC_PROVIDERS:
        _mcc_err(f"unknown provider '{provider}'")
        print("       Run 'mcc --list' to see available providers.", file=sys.stderr)
        return 1

    config = _mcc_parse_config(provider)
    rest = list(args[1:])
    key_suffix = ""
    custom_model = ""
    effort = ""
    resume = False

    index = 0
    while index < len(rest):
        item = rest[index]
        if item in ("-r", "--resume"):
            resume = True
            index += 1
        elif item in ("-m", "--model"):
            if index + 1 >= len(rest):
                _mcc_err("--model requires a value")
                return 1
            custom_model = rest[index + 1]
            index += 2
        elif item in ("-e", "--effort"):
            if index + 1 >= len(rest):
                _mcc_err(f"--effort requires a value ({' '.join(_MCC_EFFORT_LEVELS)})")
                return 1
            if rest[index + 1] not in _MCC_EFFORT_LEVELS:
                _mcc_err(f"--effort must be one of: {' '.join(_MCC_EFFORT_LEVELS)}")
                return 1
            effort = rest[index + 1]
            index += 2
        elif item.startswith("-"):
            _mcc_err(f"unknown option '{item}'")
            return 1
        else:
            if key_suffix:
                _mcc_err(f"unexpected argument '{item}'")
                return 1
            key_suffix = item
            index += 1

    key_var = config["key_env"] + (f"_{key_suffix}" if key_suffix else "")
    api_key = _mcc_env(key_var)
    if not api_key:
        _mcc_err(f"'{key_var}' is not set")
        print(f"       export {key_var}=your_api_key", file=sys.stderr)
        return 1

    base_url = _mcc_env(config["url_env"], config["default_url"]) or config["default_url"]

    if custom_model:
        big_model = custom_model
        small_model = custom_model
    else:
        big_model = _mcc_env(config["big_model_env"], config["big_model"]) or config["big_model"]
        small_model = _mcc_env(config["small_model_env"], config["small_model"]) or config["small_model"]
        big_model = big_model or small_model
        small_model = small_model or big_model

    print(f"Provider  : {provider}")
    print(f"Base URL  : {base_url}{_mcc_origin(config['url_env'])}")
    print(f"API Key   : {_mcc_mask(api_key)}  ({key_var})")
    if big_model:
        big_tag = "" if custom_model else _mcc_origin(config["big_model_env"])
        small_tag = "" if custom_model else _mcc_origin(config["small_model_env"])
        print(f"Big Model : {big_model}{big_tag}")
        print(f"Sm Model  : {small_model}{small_tag}")
        print(f"Effort    : {effort or _MCC_EFFORT_LEVELS[0]}")
    if resume:
        print("Mode      : resume")
    print()

    for name in _MCC_MANAGED_VARS:
        XSH.env.pop(name, None)

    XSH.env["ANTHROPIC_BASE_URL"] = base_url
    XSH.env["ANTHROPIC_AUTH_TOKEN"] = api_key
    if big_model:
        XSH.env["ANTHROPIC_MODEL"] = big_model
        XSH.env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = big_model
        XSH.env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = big_model
        XSH.env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = small_model
        XSH.env["CLAUDE_CODE_SUBAGENT_MODEL"] = small_model
        XSH.env["CLAUDE_CODE_EFFORT_LEVEL"] = effort or _MCC_EFFORT_LEVELS[0]
        XSH.env["API_TIMEOUT_MS"] = "600000"
        XSH.env["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] = "1"

    command = ["claude", "--dangerously-skip-permissions"]
    if resume:
        command.append("--resume")
    try:
        result = subprocess.run(command, env=XSH.env.detype(), check=False)
    except FileNotFoundError:
        print("mcc: claude not found", file=sys.stderr)
        return 127
    return result.returncode


aliases["mcc"] = _mcc
