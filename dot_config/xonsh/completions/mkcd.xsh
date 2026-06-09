import os
from pathlib import Path

from xonsh.completers.completer import add_one_completer
from xonsh.completers.tools import RichCompletion, contextual_command_completer_for


@contextual_command_completer_for("mkcd")
def _mkcd_completion(command):
    current = command.prefix
    dirname, partial = os.path.split(current)
    search_dir = Path(os.path.expanduser(dirname or "."))
    if not search_dir.is_dir():
        return None

    completions = set()
    for entry in search_dir.iterdir():
        if not entry.is_dir() or not entry.name.startswith(partial):
            continue
        value = os.path.join(dirname, entry.name) if dirname else entry.name
        completions.add(RichCompletion(value + os.sep, append_space=False))
    return completions


add_one_completer("mkcd", _mkcd_completion, "start")
