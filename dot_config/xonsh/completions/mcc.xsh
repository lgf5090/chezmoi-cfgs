from xonsh.built_ins import XSH
from xonsh.completers.completer import add_one_completer
from xonsh.completers.tools import contextual_command_completer_for


def _mcc_filter(candidates, prefix):
    return {candidate for candidate in candidates if candidate.startswith(prefix)}


@contextual_command_completer_for("mcc")
def _mcc_completion(command):
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
        return _mcc_filter([*_MCC_PROVIDERS.keys(), *_MCC_ALIASES.keys()], current)

    if pos_count == 1:
        provider = _MCC_ALIASES.get(first_pos, first_pos)
        if provider not in _MCC_PROVIDERS:
            return None
        key_env = _mcc_parse_config(provider)["key_env"]
        prefix = f"{key_env}_"
        suffixes = [name[len(prefix):] for name in XSH.env if name.startswith(prefix)]
        return _mcc_filter(suffixes, current)

    return None


add_one_completer("mcc", _mcc_completion, "start")
