import sys
from pathlib import Path

from xonsh.built_ins import XSH

if sys.platform.startswith("linux"):
    _xonsh_shells_os = "linux"
elif sys.platform == "darwin":
    _xonsh_shells_os = "macos"
elif sys.platform.startswith("freebsd"):
    _xonsh_shells_os = "freebsd"
elif sys.platform.startswith("cygwin"):
    _xonsh_shells_os = "cygwin"
elif sys.platform.startswith(("win32", "msys", "mingw")):
    _xonsh_shells_os = "windows"
else:
    _xonsh_shells_os = "unknown"

_xonsh_proc_version = Path("/proc/version")
if _xonsh_shells_os == "linux" and _xonsh_proc_version.is_file():
    try:
        if any(token in _xonsh_proc_version.read_text(errors="ignore").lower() for token in ("microsoft", "wsl")):
            _xonsh_shells_os = "wsl"
    except OSError:
        pass

XSH.env["SHELLS_OS"] = _xonsh_shells_os

del _xonsh_shells_os
del _xonsh_proc_version
