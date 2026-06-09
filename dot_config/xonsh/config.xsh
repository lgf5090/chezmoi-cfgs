# Fish-style xonsh entrypoint.

from pathlib import Path

try:
    _xonsh_config_file = Path(__file__).resolve()
except NameError:
    _xonsh_config_file = Path.cwd() / "config.xsh"

$XONSH_CONFIG_DIR = str(_xonsh_config_file.parent)

_xonsh_config_dir = None
_xonsh_config_part = None

for _xonsh_config_subdir in ("functions", "conf.d", "completions"):
    _xonsh_config_dir = Path($XONSH_CONFIG_DIR) / _xonsh_config_subdir
    if not _xonsh_config_dir.is_dir():
        continue

    for _xonsh_config_part in sorted(_xonsh_config_dir.glob("*.xsh")):
        if _xonsh_config_part.is_file():
            source @(str(_xonsh_config_part))

del _xonsh_config_file
del _xonsh_config_subdir
del _xonsh_config_dir
del _xonsh_config_part
