from pathlib import Path

from xonsh.built_ins import XSH

_xonsh_conda_discovery = str(XSH.env.get("XONSH_CONDA_DISCOVERY", XSH.env.get("BASH_CONDA_DISCOVERY", "0"))) == "1"
_xonsh_conda_exe = None
_xonsh_mamba_exe = None
_xonsh_micromamba_exe = None

if XSH.env.get("ANACONDA_HOME"):
    _xonsh_conda_home = Path(str(XSH.env["ANACONDA_HOME"]))
    for _xonsh_conda_candidate in (
        _xonsh_conda_home / "bin" / "conda",
        _xonsh_conda_home / "condabin" / "conda",
        _xonsh_conda_home / "Scripts" / "conda.exe",
        _xonsh_conda_home / "condabin" / "conda.bat",
    ):
        if _xonsh_conda_candidate.is_file():
            _xonsh_conda_exe = str(_xonsh_conda_candidate)
            break
    for _xonsh_mamba_candidate in (
        _xonsh_conda_home / "bin" / "mamba",
        _xonsh_conda_home / "condabin" / "mamba",
        _xonsh_conda_home / "Scripts" / "mamba.exe",
    ):
        if _xonsh_mamba_candidate.is_file():
            _xonsh_mamba_exe = str(_xonsh_mamba_candidate)
            break

if XSH.env.get("MICROMAMBA_EXE") and Path(str(XSH.env["MICROMAMBA_EXE"])).is_file():
    _xonsh_micromamba_exe = str(XSH.env["MICROMAMBA_EXE"])

if _xonsh_conda_discovery:
    import shutil

    if not _xonsh_conda_exe:
        _xonsh_conda_exe = shutil.which("conda")
    if not _xonsh_mamba_exe:
        _xonsh_mamba_exe = shutil.which("mamba")
    if not _xonsh_micromamba_exe:
        _xonsh_micromamba_exe = shutil.which("micromamba")

if not _xonsh_mamba_exe and _xonsh_conda_exe:
    _xonsh_conda_bin = Path(_xonsh_conda_exe).parent
    for _xonsh_mamba_candidate in (
        _xonsh_conda_bin / "mamba",
        _xonsh_conda_bin / "mamba.exe",
    ):
        if _xonsh_mamba_candidate.is_file():
            _xonsh_mamba_exe = str(_xonsh_mamba_candidate)
            break

del _xonsh_conda_discovery


def _xonsh_load_conda():
    if not _xonsh_conda_exe:
        return False
    import subprocess

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
        if current and callable(current[0]):
            if getattr(current[0], "func", None) is fallback:
                return None
            return current[0]([*current[1:], *args], stdin=stdin)

        import subprocess

        result = subprocess.run([*current, *args], env=XSH.env.detype(), check=False)
        return result.returncode
    if isinstance(current, str):
        import subprocess

        result = subprocess.run([current, *args], env=XSH.env.detype(), check=False)
        return result.returncode
    return None


def _conda(args, stdin=None):
    _xonsh_load_conda()
    loaded = _xonsh_run_loaded_alias("conda", _conda, args, stdin=stdin)
    if loaded is not None:
        return loaded
    if not _xonsh_conda_exe:
        return 127
    import subprocess

    result = subprocess.run([_xonsh_conda_exe, *args], env=XSH.env.detype(), check=False)
    return result.returncode


def _mamba(args, stdin=None):
    _xonsh_load_conda()
    loaded = _xonsh_run_loaded_alias("mamba", _mamba, args, stdin=stdin)
    if loaded is not None:
        return loaded
    if not _xonsh_mamba_exe:
        return 127
    import subprocess

    result = subprocess.run([_xonsh_mamba_exe, *args], env=XSH.env.detype(), check=False)
    return result.returncode


if _xonsh_conda_exe:
    aliases["conda"] = _conda
    if _xonsh_mamba_exe:
        aliases["mamba"] = _mamba

if _xonsh_micromamba_exe:

    def _micromamba(args, stdin=None):
        import subprocess

        hook = subprocess.run([_xonsh_micromamba_exe, "shell", "hook", "--shell", "xonsh"], capture_output=True, text=True, check=False)
        if hook.returncode == 0 and hook.stdout:
            XSH.builtins.execx(hook.stdout, "exec", XSH.ctx, filename="micromamba")
            loaded = _xonsh_run_loaded_alias("micromamba", _micromamba, args, stdin=stdin)
            if loaded is not None:
                return loaded
        result = subprocess.run([_xonsh_micromamba_exe, *args], env=XSH.env.detype(), check=False)
        return result.returncode

    aliases["micromamba"] = _micromamba
