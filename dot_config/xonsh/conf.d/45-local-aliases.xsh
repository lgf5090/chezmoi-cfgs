from pathlib import Path

from xonsh.built_ins import XSH

if globals().get("_XLOCAL_LOADER_VERSION") != 4:
    source @(str(Path($XONSH_CONFIG_DIR) / "conf.d" / "01-helpers.xsh"))

_xonsh_local_aliases_file = (
    XSH.env.get("XONSH_LOCAL_ALIASES_FILE")
    or XSH.env.get("BASH_LOCAL_ALIASES_FILE")
    or str(Path.home() / ".aliases")
)
_xload_aliases(_xonsh_local_aliases_file)

del _xonsh_local_aliases_file
