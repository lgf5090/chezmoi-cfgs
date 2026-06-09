import os
import subprocess
import tempfile
from pathlib import Path

from xonsh.built_ins import XSH
from xonsh.dirstack import cd as _xonsh_cd


def _y(args, stdin=None):
    tmp = tempfile.NamedTemporaryFile(prefix="yazi-cwd.", delete=False)
    tmp.close()
    try:
        result = subprocess.run(["yazi", *args, f"--cwd-file={tmp.name}"], env=XSH.env.detype(), check=False)
        path = Path(tmp.name)
        if path.is_file() and path.stat().st_size > 0:
            target = path.read_text(errors="ignore").strip("\0\n")
            if target and Path(target).is_dir() and target != str(Path.cwd()):
                _xonsh_cd([target])
        return result.returncode
    finally:
        try:
            os.unlink(tmp.name)
        except OSError:
            pass


aliases["y"] = _y
