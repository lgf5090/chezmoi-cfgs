from xonsh.built_ins import XSH

_MCC_PROVIDER_NAMES = ("agentrouter", "anyrouter", "deepseek", "moonshot", "glm", "siliconflow")
_MCC_PROVIDER_SET = set(_MCC_PROVIDER_NAMES)
_MCC_KEY_ENVS = {
    "agentrouter": "AGENTROUTER_API_KEY",
    "anyrouter": "ANYROUTER_API_KEY",
    "deepseek": "DEEPSEEK_API_KEY",
    "moonshot": "MOONSHOT_API_KEY",
    "glm": "GLM_API_KEY",
    "siliconflow": "SILICONFLOW_API_KEY",
}

_MCC_ALIASES = {
    "tr": "agentrouter",
    "yr": "anyrouter",
    "ds": "deepseek",
    "km": "moonshot",
    "kimi": "moonshot",
    "sf": "siliconflow",
}

_MCC_EFFORT_LEVELS = ("max", "normal", "min")


def _mcc_filter(candidates, prefix):
    return {candidate for candidate in candidates if candidate.startswith(prefix)}


def _mcc_completion(context):
    command = getattr(context, "command", None)
    if command is None or not command.completing_command("mcc"):
        return None

    current = command.prefix
    completed = [arg.value for arg in command.args[1:command.arg_index]]
    previous = completed[-1] if completed else ""

    if previous in ("-m", "--model"):
        return None
    if previous in ("-e", "--effort"):
        return _mcc_filter(_MCC_EFFORT_LEVELS, current)

    if current.startswith("-"):
        return _mcc_filter(["-l", "--list", "-r", "--resume", "-m", "--model", "-e", "--effort", "-h", "--help"], current)

    pos_count = 0
    first_pos = ""
    skip_next = False
    for item in completed:
        if skip_next:
            skip_next = False
            continue
        if item in ("-m", "--model", "-e", "--effort"):
            skip_next = True
        elif item.startswith("-"):
            continue
        else:
            pos_count += 1
            if pos_count == 1:
                first_pos = item

    if pos_count == 0:
        return _mcc_filter((*_MCC_PROVIDER_NAMES, *_MCC_ALIASES.keys()), current)

    if pos_count == 1:
        provider = _MCC_ALIASES.get(first_pos, first_pos)
        if provider not in _MCC_PROVIDER_SET:
            return None
        key_env = _MCC_KEY_ENVS[provider]
        prefix = f"{key_env}_"
        suffixes = [name[len(prefix):] for name in XSH.env if name.startswith(prefix)]
        return _mcc_filter(suffixes, current)

    return None


_mcc_completion.contextual = True
XSH.completers["mcc"] = _mcc_completion
