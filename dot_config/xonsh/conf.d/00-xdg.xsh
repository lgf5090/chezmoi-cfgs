from pathlib import Path

from xonsh.built_ins import XSH

_xhome = Path.home()
_xdg_defaults = {
    "XDG_CONFIG_HOME": _xhome / ".config",
    "XDG_DATA_HOME": _xhome / ".local" / "share",
    "XDG_STATE_HOME": _xhome / ".local" / "state",
    "XDG_CACHE_HOME": _xhome / ".cache",
}

for _xdg_name, _xdg_value in _xdg_defaults.items():
    if not XSH.env.get(_xdg_name):
        XSH.env[_xdg_name] = str(_xdg_value)

for _xdg_dir in (
    Path(XSH.env["XDG_STATE_HOME"]) / "xonsh",
    Path(XSH.env["XDG_CACHE_HOME"]) / "xonsh",
):
    try:
        _xdg_dir.mkdir(parents=True, exist_ok=True)
    except OSError:
        pass

del _xhome
del _xdg_defaults
del _xdg_name
del _xdg_value
del _xdg_dir
