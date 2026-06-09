import sys
from pathlib import Path

from xonsh.built_ins import XSH

if XSH.env.get("SHELLS_OS") in ("linux", "wsl", "cygwin", "windows"):
    aliases["ls"] = "ls --color=auto"
elif XSH.env.get("SHELLS_OS") in ("macos", "freebsd"):
    aliases["ls"] = "ls -G"

aliases["ll"] = "ls -alFh"
aliases["la"] = "ls -A"
aliases["l"] = "ls -CF"
aliases["lt"] = "ls -alFht"

aliases["grep"] = "grep --color=auto"
aliases["fgrep"] = "fgrep --color=auto"
aliases["egrep"] = "egrep --color=auto"

aliases[".."] = "cd .."
aliases["..."] = "cd ../.."
aliases["...."] = "cd ../../.."
aliases["md"] = "mkdir -p"
aliases["now"] = "date +%Y-%m-%dT%H:%M:%S%z"
aliases["cls"] = "clear"


def _xonsh_reload(args, stdin=None):
    if args:
        print("usage: reload", file=sys.stderr)
        return 2
    source @(str(Path($XONSH_CONFIG_DIR) / "config.xsh"))


aliases["reload"] = _xonsh_reload
