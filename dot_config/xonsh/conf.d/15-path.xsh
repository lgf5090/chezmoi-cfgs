import os
from pathlib import Path

from xonsh.built_ins import XSH

_xhome = Path.home()


def _xenv_paths(name):
    value = XSH.env.get(name)
    if value is None:
        return []
    if isinstance(value, (str, bytes)):
        return [part for part in os.fsdecode(value).split(os.pathsep) if part]
    return [str(part) for part in value if str(part)]


_xpath_append(
    _xhome / ".lmstudio" / "bin",
    _xhome / ".local" / "bin",
    _xhome / "bin",
    _xhome / "Applications",
    _xhome / ".local" / "Applications",
)

_xpath_prepend(
    Path(str(XSH.env["ASDF_DIR"])) / "bin" if XSH.env.get("ASDF_DIR") else None,
    Path(str(XSH.env["RBENV_ROOT"])) / "bin" if XSH.env.get("RBENV_ROOT") else None,
    Path(str(XSH.env["NODENV_ROOT"])) / "bin" if XSH.env.get("NODENV_ROOT") else None,
    Path(str(XSH.env["GOENV_ROOT"])) / "bin" if XSH.env.get("GOENV_ROOT") else None,
    Path(str(XSH.env["JENV_ROOT"])) / "bin" if XSH.env.get("JENV_ROOT") else None,
    Path(str(XSH.env.get("CARGO_HOME", _xhome / ".cargo"))) / "bin",
    _xhome / ".rd" / "bin",
    _xhome / ".opencode" / "bin",
)

_xpath_prepend(
    Path(str(XSH.env["BUN_INSTALL"])) / "bin" if XSH.env.get("BUN_INSTALL") else None,
    Path(str(XSH.env["DENO_INSTALL"])) / "bin" if XSH.env.get("DENO_INSTALL") else None,
    Path(str(XSH.env["NPM_CONFIG_PREFIX"])) / "bin" if XSH.env.get("NPM_CONFIG_PREFIX") else None,
    XSH.env.get("PNPM_HOME"),
    _xhome / ".yarn" / "bin",
    _xhome / ".config" / "yarn" / "global" / "node_modules" / ".bin",
    Path(str(XSH.env["VOLTA_HOME"])) / "bin" if XSH.env.get("VOLTA_HOME") else None,
    _xhome / ".volta" / "bin",
    XSH.env.get("FNM_DIR"),
    _xhome / ".local" / "share" / "npm" / "bin",
)

_xpath_prepend(
    Path(str(XSH.env["PYENV_ROOT"])) / "bin" if XSH.env.get("PYENV_ROOT") else None,
    Path(str(XSH.env["ANACONDA_HOME"])) / "bin" if XSH.env.get("ANACONDA_HOME") else None,
    Path(str(XSH.env["POETRY_HOME"])) / "bin" if XSH.env.get("POETRY_HOME") else None,
    _xhome / ".poetry" / "bin",
    _xhome / ".local" / "pipx" / "bin",
)

_xpath_prepend(*[Path(part) / "bin" for part in _xenv_paths("GOPATH")])
_xpath_prepend(*[Path(part) / "bin" for part in _xenv_paths("GOROOT")])

if XSH.env.get("SHELLS_OS", "unknown") in ("linux", "wsl"):
    _xpath_append(
        Path("/snap/bin"),
        Path("/var/lib/snapd/snap/bin"),
        Path("/var/lib/flatpak/exports/bin"),
        _xhome / ".local" / "share" / "flatpak" / "exports" / "bin",
        Path("/opt/bin"),
    )

if XSH.env.get("SHELLS_OS", "unknown") == "wsl":
    _xpath_append(
        Path("/mnt/c/Program Files/Microsoft VS Code/bin"),
        Path(f"/mnt/c/Users/{XSH.env.get('USER', '')}/AppData/Local/Programs/Microsoft VS Code/bin"),
    )
elif XSH.env.get("SHELLS_OS", "unknown") == "cygwin":
    _xpath_prepend(Path("/mingw64/bin"))
    _xpath_append(
        Path("/cygdrive/c/Program Files/Microsoft VS Code/bin"),
        Path(f"/cygdrive/c/Users/{XSH.env.get('USER', '')}/AppData/Local/Programs/Microsoft VS Code/bin"),
    )
elif XSH.env.get("SHELLS_OS", "unknown") == "windows":
    _xpath_prepend(Path("/mingw64/bin"))
    _xpath_append(
        Path("/c/Program Files/Microsoft VS Code/bin"),
        Path(f"/c/Users/{XSH.env.get('USER', '')}/AppData/Local/Programs/Microsoft VS Code/bin"),
    )

_xpath_prepend(
    _xhome / ".nix-profile" / "bin",
    Path("/run/current-system/sw/bin"),
    Path("/nix/var/nix/profiles/default/bin"),
)

for _xbrew in (
    Path("/home/linuxbrew/.linuxbrew/bin/brew"),
    _xhome / ".linuxbrew" / "bin" / "brew",
    Path("/opt/homebrew/bin/brew"),
    Path("/usr/local/bin/brew"),
):
    if not (_xbrew.is_file() and os.access(_xbrew, os.X_OK)):
        continue
    _xbrew_bin = _xbrew.parent
    _xbrew_prefix = _xbrew_bin.parent
    _xpath_prepend(_xbrew_prefix / "sbin", _xbrew_prefix / "bin")
    XSH.env["HOMEBREW_PREFIX"] = str(_xbrew_prefix)
    XSH.env["HOMEBREW_CELLAR"] = str(_xbrew_prefix / "Cellar")
    if str(_xbrew_prefix) == "/opt/homebrew" or str(_xbrew_prefix).endswith("/Homebrew"):
        XSH.env["HOMEBREW_REPOSITORY"] = str(_xbrew_prefix)
    else:
        XSH.env["HOMEBREW_REPOSITORY"] = str(_xbrew_prefix / "Homebrew")
    if "MANPATH" in XSH.env:
        XSH.env["MANPATH"] = ":" + str(XSH.env["MANPATH"]).lstrip(":")
    XSH.env["INFOPATH"] = f"{_xbrew_prefix / 'share' / 'info'}:{XSH.env.get('INFOPATH', '')}"
    break

del _xhome
del _xbrew
del _xenv_paths
