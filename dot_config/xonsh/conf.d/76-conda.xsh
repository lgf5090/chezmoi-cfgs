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


def _xonsh_run_loaded_alias(name, fallback, args, stdin=None):
    current = aliases.get(name)
    if current is fallback:
        return None
    if callable(current):
        return current(args, stdin=stdin)
    if isinstance(current, (list, tuple)):
        result = subprocess.run([*current, *args], env=XSH.env.detype(), check=False)
        return result.returncode
    if isinstance(current, str):
        result = subprocess.run([current, *args], env=XSH.env.detype(), check=False)
        return result.returncode
    return None


def _conda(args, stdin=None):
    _xonsh_load_conda()
    loaded = _xonsh_run_loaded_alias("conda", _conda, args, stdin=stdin)
    if loaded is not None:
        return loaded
    result = subprocess.run([_xonsh_conda_exe, *args], env=XSH.env.detype(), check=False)
    return result.returncode


def _mamba(args, stdin=None):
    _xonsh_load_conda()
    loaded = _xonsh_run_loaded_alias("mamba", _mamba, args, stdin=stdin)
    if loaded is not None:
        return loaded
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
            loaded = _xonsh_run_loaded_alias("micromamba", _micromamba, args, stdin=stdin)
            if loaded is not None:
                return loaded
        result = subprocess.run([_xonsh_micromamba_exe, *args], env=XSH.env.detype(), check=False)
        return result.returncode

    aliases["micromamba"] = _micromamba
