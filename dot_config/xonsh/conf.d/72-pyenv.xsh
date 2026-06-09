import shutil
import subprocess
from pathlib import Path

from xonsh.built_ins import XSH

if XSH.env.get("PYENV_ROOT"):
    _xpath_prepend(Path(str(XSH.env["PYENV_ROOT"])) / "bin", Path(str(XSH.env["PYENV_ROOT"])) / "shims")

if shutil.which("pyenv"):
    _xonsh_pyenv_init = subprocess.run(["pyenv", "init", "-"], capture_output=True, text=True, check=False)
    if _xonsh_pyenv_init.returncode == 0 and "xonsh" in _xonsh_pyenv_init.stdout.lower():
        XSH.builtins.execx(_xonsh_pyenv_init.stdout, "exec", XSH.ctx, filename="pyenv")
    _xonsh_pyenv_virtualenv = subprocess.run(["pyenv", "virtualenv-init", "-"], capture_output=True, text=True, check=False)
    if _xonsh_pyenv_virtualenv.returncode == 0 and "xonsh" in _xonsh_pyenv_virtualenv.stdout.lower():
        XSH.builtins.execx(_xonsh_pyenv_virtualenv.stdout, "exec", XSH.ctx, filename="pyenv-virtualenv")
