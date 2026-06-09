import shutil
import subprocess
from pathlib import Path

from xonsh.built_ins import XSH

if XSH.env.get("PYENV_ROOT"):
    _xpath_prepend(Path(str(XSH.env["PYENV_ROOT"])) / "bin", Path(str(XSH.env["PYENV_ROOT"])) / "shims")

if shutil.which("pyenv"):
    for _xonsh_pyenv_cmd, _xonsh_pyenv_file in (
        (["pyenv", "init", "-", "xonsh"], "pyenv"),
        (["pyenv", "virtualenv-init", "-", "xonsh"], "pyenv-virtualenv"),
    ):
        _xonsh_pyenv_init = subprocess.run(_xonsh_pyenv_cmd, capture_output=True, text=True, check=False)
        if _xonsh_pyenv_init.returncode == 0 and _xonsh_pyenv_init.stdout:
            XSH.builtins.execx(_xonsh_pyenv_init.stdout, "exec", XSH.ctx, filename=_xonsh_pyenv_file)
