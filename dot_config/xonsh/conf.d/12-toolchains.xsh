import os
import subprocess
from pathlib import Path

from xonsh.built_ins import XSH

_xhome = Path.home()

_xenv_default("NPM_CONFIG_PREFIX", _xhome / ".npm-global")
_xenv_default("PNPM_HOME", _xhome / ".pnpm-global")

if not XSH.env.get("FNM_DIR"):
    for _xfnm_dir in (Path(XSH.env.get("XDG_DATA_HOME", _xhome / ".local" / "share")) / "fnm", _xhome / ".fnm"):
        if _xfnm_dir.is_dir():
            XSH.env["FNM_DIR"] = str(_xfnm_dir)
            break

if (_xhome / ".volta").is_dir():
    XSH.env["VOLTA_HOME"] = str(_xhome / ".volta")
if (_xhome / ".bun").is_dir():
    XSH.env["BUN_INSTALL"] = str(_xhome / ".bun")
if (_xhome / ".deno").is_dir():
    XSH.env["DENO_INSTALL"] = str(_xhome / ".deno")

_xenv_default("GOPATH", _xhome / "go")

if not XSH.env.get("GOROOT"):
    for _xgoroot in (
        Path("/home/linuxbrew/.linuxbrew/opt/go/libexec"),
        Path("/opt/homebrew/opt/go/libexec"),
        Path("/usr/local/go"),
        _xhome / ".local" / "go",
    ):
        if _xgoroot.is_dir():
            XSH.env["GOROOT"] = str(_xgoroot)
            break

if not XSH.env.get("ANACONDA_HOME"):
    for _xconda in (_xhome / "anaconda3", _xhome / "miniconda3", Path("/opt/anaconda3"), Path("/opt/miniconda3")):
        if _xconda.is_dir():
            XSH.env["ANACONDA_HOME"] = str(_xconda)
            break

if not XSH.env.get("POETRY_HOME") and (_xhome / ".poetry").is_dir():
    XSH.env["POETRY_HOME"] = str(_xhome / ".poetry")

if not XSH.env.get("PYENV_ROOT") and (_xhome / ".pyenv").is_dir():
    XSH.env["PYENV_ROOT"] = str(_xhome / ".pyenv")

if not XSH.env.get("ASDF_DIR"):
    _xasdf_candidates = [
        _xhome / ".asdf",
        Path("/home/linuxbrew/.linuxbrew/opt/asdf/libexec"),
        Path("/opt/homebrew/opt/asdf/libexec"),
        Path("/usr/local/opt/asdf/libexec"),
    ]
    if XSH.env.get("HOMEBREW_PREFIX"):
        _xasdf_candidates.insert(1, Path(str(XSH.env["HOMEBREW_PREFIX"])) / "opt" / "asdf" / "libexec")
    for _xasdf_dir in _xasdf_candidates:
        if _xasdf_dir.is_dir():
            XSH.env["ASDF_DIR"] = str(_xasdf_dir)
            break

if not XSH.env.get("ASDF_DATA_DIR") and XSH.env.get("ASDF_DIR"):
    if Path(str(XSH.env["ASDF_DIR"])) == _xhome / ".asdf":
        XSH.env["ASDF_DATA_DIR"] = str(XSH.env["ASDF_DIR"])
    else:
        XSH.env["ASDF_DATA_DIR"] = str(Path(XSH.env.get("XDG_DATA_HOME", _xhome / ".local" / "share")) / "asdf")

for _xenv_name, _xenv_dir in (
    ("RBENV_ROOT", _xhome / ".rbenv"),
    ("NODENV_ROOT", _xhome / ".nodenv"),
    ("GOENV_ROOT", _xhome / ".goenv"),
    ("JENV_ROOT", _xhome / ".jenv"),
    ("SDKMAN_DIR", _xhome / ".sdkman"),
):
    if XSH.env.get(_xenv_name):
        XSH.env[_xenv_name] = str(XSH.env[_xenv_name])
    elif _xenv_dir.is_dir():
        XSH.env[_xenv_name] = str(_xenv_dir)

if not XSH.env.get("JAVA_HOME"):
    _xjava_home = None
    if os.access("/usr/libexec/java_home", os.X_OK):
        _xjava_result = subprocess.run(["/usr/libexec/java_home"], capture_output=True, text=True, check=False)
        if _xjava_result.returncode == 0 and _xjava_result.stdout.strip():
            _xjava_home = _xjava_result.stdout.strip()
    else:
        for _xjdk in (
            Path("/usr/lib/jvm/default-java"),
            Path("/usr/lib/jvm/default"),
            Path("/usr/lib/jvm/java-21-openjdk-amd64"),
            Path("/usr/lib/jvm/java-17-openjdk-amd64"),
            Path("/usr/lib/jvm/java-11-openjdk-amd64"),
        ):
            if _xjdk.is_dir():
                _xjava_home = str(_xjdk)
                break
    if _xjava_home:
        XSH.env["JAVA_HOME"] = _xjava_home


def _xenv_path_prepend(name, directory):
    directory = str(directory)
    if not os.path.isdir(directory):
        return
    value = XSH.env.get(name, "")
    if isinstance(value, (str, bytes)):
        parts = [part for part in os.fsdecode(value).split(os.pathsep) if part]
    else:
        parts = [str(part) for part in value if str(part)]
    if directory not in parts:
        parts.insert(0, directory)
        XSH.env[name] = parts


if XSH.env.get("SHELLS_OS", "unknown") in ("linux", "wsl"):
    for _xlibdir in (Path("/usr/lib/x86_64-linux-gnu"), Path("/usr/lib/aarch64-linux-gnu")):
        if not _xlibdir.is_dir():
            continue
        _xenv_path_prepend("LIBRARY_PATH", _xlibdir)
        _xenv_path_prepend("LD_LIBRARY_PATH", _xlibdir)
        _xrustflags = str(XSH.env.get("RUSTFLAGS", ""))
        if f" -L {_xlibdir} " not in f" {_xrustflags} ":
            XSH.env["RUSTFLAGS"] = f"-L {_xlibdir}" + (f" {_xrustflags}" if _xrustflags else "")
        break

_xenv_default("DOCKER_BUILDKIT", "1")
_xenv_default("COMPOSE_DOCKER_CLI_BUILD", "1")

del _xhome
del _xenv_name
del _xenv_dir
del _xenv_path_prepend
