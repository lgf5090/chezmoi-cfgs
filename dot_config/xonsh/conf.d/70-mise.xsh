import os
import shutil
import subprocess
from pathlib import Path

from xonsh.built_ins import XSH

_xenv_default("MISE_DATA_DIR", Path(XSH.env.get("XDG_DATA_HOME", Path.home() / ".local" / "share")) / "mise")

if not XSH.env.get("MISE_CACHE_DIR"):
    _xonsh_mise_cache = Path(XSH.env.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "mise"
    try:
        _xonsh_mise_cache.mkdir(parents=True, exist_ok=True)
    except OSError:
        pass
    if not os.access(_xonsh_mise_cache, os.W_OK):
        _xonsh_mise_cache = Path(os.environ.get("TMPDIR", "/tmp")) / f"mise-{os.getuid()}"
        _xonsh_mise_cache.mkdir(parents=True, exist_ok=True)
    XSH.env["MISE_CACHE_DIR"] = str(_xonsh_mise_cache)

_xonsh_mise = None
for _xonsh_mise_candidate in (
    XSH.env.get("MISE_EXE"),
    Path.home() / ".local" / "bin" / "mise",
    Path("/home/linuxbrew/.linuxbrew/bin/mise"),
    Path.home() / ".linuxbrew" / "bin" / "mise",
    Path("/opt/homebrew/bin/mise"),
    Path("/usr/local/bin/mise"),
    Path("/opt/mise/bin/mise"),
):
    if _xonsh_mise_candidate and os.access(str(_xonsh_mise_candidate), os.X_OK):
        _xonsh_mise = str(_xonsh_mise_candidate)
        break

if not _xonsh_mise and XSH.env.get("SHELLS_OS") == "windows":
    for _xonsh_mise_candidate in (
        Path.home() / "scoop" / "shims" / "mise.exe",
        Path(str(XSH.env.get("PROGRAMDATA", ""))) / "scoop" / "shims" / "mise.exe" if XSH.env.get("PROGRAMDATA") else None,
        Path(str(XSH.env.get("LOCALAPPDATA", ""))) / "Microsoft" / "WinGet" / "Links" / "mise.exe" if XSH.env.get("LOCALAPPDATA") else None,
    ):
        if _xonsh_mise_candidate and os.access(str(_xonsh_mise_candidate), os.X_OK):
            _xonsh_mise = str(_xonsh_mise_candidate)
            break

if not _xonsh_mise and str(XSH.env.get("XONSH_MISE_DISCOVERY", XSH.env.get("BASH_MISE_DISCOVERY", "0"))) == "1":
    _xonsh_mise = shutil.which("mise")

if _xonsh_mise:
    _xonsh_mise_init = subprocess.run([_xonsh_mise, "activate", "xonsh"], capture_output=True, text=True, check=False)
    if _xonsh_mise_init.returncode == 0 and _xonsh_mise_init.stdout:
        XSH.builtins.execx(_xonsh_mise_init.stdout, "exec", XSH.ctx, filename="mise")

_xpath_prepend(Path.home() / ".mise" / "shims", Path(str(XSH.env["MISE_DATA_DIR"])) / "shims")

del _xonsh_mise
