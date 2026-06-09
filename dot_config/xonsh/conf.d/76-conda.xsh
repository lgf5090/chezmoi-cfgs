import shutil
import subprocess
from pathlib import Path

from xonsh.built_ins import XSH

_xonsh_conda_exe = None
if XSH.env.get("ANACONDA_HOME") and (Path(str(XSH.env["ANACONDA_HOME"])) / "bin" / "conda").is_file():
    _xonsh_conda_exe = str(Path(str(XSH.env["ANACONDA_HOME"])) / "bin" / "conda")
elif shutil.which("conda"):
    _xonsh_conda_exe = shutil.which("conda")


def _xonsh_load_conda():
    if not _xonsh_conda_exe:
        return False
    hook = subprocess.run([_xonsh_conda_exe, "shell.xonsh", "hook"], capture_output=True, text=True, check=False)
    if hook.returncode == 0 and hook.stdout:
        XSH.builtins.execx(hook.stdout, "exec", XSH.ctx, filename="conda")
    else:
        _xpath_prepend(Path(_xonsh_conda_exe).parent)
    return True


def _conda(args, stdin=None):
    _xonsh_load_conda()
    current = aliases.get("conda")
    if current is not _conda:
        return current(args, stdin=stdin)
    result = subprocess.run([_xonsh_conda_exe, *args], env=XSH.env.detype(), check=False)
    return result.returncode


def _mamba(args, stdin=None):
    _xonsh_load_conda()
    current = aliases.get("mamba")
    if current is not _mamba:
        return current(args, stdin=stdin)
    exe = shutil.which("mamba")
    if not exe:
        return 127
    result = subprocess.run([exe, *args], env=XSH.env.detype(), check=False)
    return result.returncode


if _xonsh_conda_exe:
    aliases["conda"] = _conda
    if shutil.which("mamba"):
        aliases["mamba"] = _mamba

if shutil.which("micromamba"):
    _xonsh_micromamba_exe = shutil.which("micromamba")

    def _micromamba(args, stdin=None):
        hook = subprocess.run([_xonsh_micromamba_exe, "shell", "hook", "--shell", "xonsh"], capture_output=True, text=True, check=False)
        if hook.returncode == 0 and hook.stdout:
            XSH.builtins.execx(hook.stdout, "exec", XSH.ctx, filename="micromamba")
            current = aliases.get("micromamba")
            if current is not _micromamba:
                return current(args, stdin=stdin)
        result = subprocess.run([_xonsh_micromamba_exe, *args], env=XSH.env.detype(), check=False)
        return result.returncode

    aliases["micromamba"] = _micromamba
