from pathlib import Path

from xonsh.built_ins import XSH

if globals().get("_XLOCAL_LOADER_VERSION") != 4:
    source @(str(Path($XONSH_CONFIG_DIR) / "conf.d" / "01-helpers.xsh"))

_xonsh_local_envs_file = (
    XSH.env.get("XONSH_LOCAL_ENVS_FILE")
    or XSH.env.get("BASH_LOCAL_ENVS_FILE")
    or str(Path.home() / ".envs")
)
_xload_envs(_xonsh_local_envs_file)

del _xonsh_local_envs_file
