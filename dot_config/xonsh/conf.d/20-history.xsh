from pathlib import Path

from xonsh.built_ins import XSH

_xonsh_history_dir = Path(XSH.env["XDG_STATE_HOME"]) / "xonsh"
try:
    _xonsh_history_dir.mkdir(parents=True, exist_ok=True)
except OSError:
    pass

XSH.env["XONSH_HISTORY_FILE"] = str(_xonsh_history_dir / "history.json")
XSH.env["XONSH_HISTORY_SIZE"] = (100000, "commands")
XSH.env["HISTCONTROL"] = {"ignoredups", "ignorespace", "erasedups"}
XSH.env["HISTSIZE"] = "100000"
XSH.env["HISTFILESIZE"] = "100000"
XSH.env["HISTTIMEFORMAT"] = "%F %T "

del _xonsh_history_dir
