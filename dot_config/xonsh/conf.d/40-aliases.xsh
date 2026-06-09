import sys
from pathlib import Path

from xonsh.built_ins import XSH

_xonsh_builtin_aliases = {
    "ll": "ls -alFh",
    "la": "ls -A",
    "l": "ls -CF",
    "lt": "ls -alFht",
    "grep": "grep --color=auto",
    "fgrep": "fgrep --color=auto",
    "egrep": "egrep --color=auto",
    "..": "cd ..",
    "...": "cd ../..",
    "....": "cd ../../..",
    "md": "mkdir -p",
    "now": "date +%Y-%m-%dT%H:%M:%S%z",
    "cls": "clear",
}

if XSH.env.get("SHELLS_OS") in ("linux", "wsl", "cygwin", "windows"):
    _xonsh_builtin_aliases["ls"] = "ls --color=auto"
elif XSH.env.get("SHELLS_OS") in ("macos", "freebsd"):
    _xonsh_builtin_aliases["ls"] = "ls -G"

aliases.update(_xonsh_builtin_aliases)


def _xonsh_reload(args, stdin=None):
    if args:
        print("usage: reload", file=sys.stderr)
        return 2
    source @(str(Path($XONSH_CONFIG_DIR) / "config.xsh"))


aliases["reload"] = _xonsh_reload

del _xonsh_builtin_aliases
