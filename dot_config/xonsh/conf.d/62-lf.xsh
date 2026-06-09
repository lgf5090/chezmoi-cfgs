import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from xonsh.built_ins import XSH
from xonsh.dirstack import cd as _xonsh_cd

_xonsh_lf_icons = Path(XSH.env["XDG_CONFIG_HOME"]) / "lf" / "icons"
if _xonsh_lf_icons.is_file():
    XSH.env["LF_ICONS"] = ":".join(_xonsh_lf_icons.read_text(errors="ignore").splitlines())


def _lf(args, stdin=None):
    tmp = tempfile.NamedTemporaryFile(prefix="lf-cwd.", delete=False)
    tmp.close()
    try:
        result = subprocess.run(["lf", f"-last-dir-path={tmp.name}", *args], env=XSH.env.detype(), check=False)
        path = Path(tmp.name)
        if path.is_file() and path.stat().st_size > 0:
            target = path.read_text(errors="ignore").strip()
            if target and Path(target).is_dir() and target != str(Path.cwd()):
                _xonsh_cd([target])
        return result.returncode
    finally:
        try:
            os.unlink(tmp.name)
        except OSError:
            pass


if shutil.which("lf"):
    aliases["lf"] = _lf

del _xonsh_lf_icons
