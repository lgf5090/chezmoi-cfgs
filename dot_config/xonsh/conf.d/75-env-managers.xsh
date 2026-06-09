import shutil
import subprocess
from pathlib import Path

from xonsh.built_ins import XSH

for _xonsh_manager, _xonsh_root_var in (
    ("rbenv", "RBENV_ROOT"),
    ("nodenv", "NODENV_ROOT"),
    ("goenv", "GOENV_ROOT"),
    ("jenv", "JENV_ROOT"),
):
    if XSH.env.get(_xonsh_root_var):
        _xpath_prepend(Path(str(XSH.env[_xonsh_root_var])) / "bin", Path(str(XSH.env[_xonsh_root_var])) / "shims")
    if shutil.which(_xonsh_manager):
        _xonsh_manager_init = subprocess.run([_xonsh_manager, "init", "-", "xonsh"], capture_output=True, text=True, check=False)
        if _xonsh_manager_init.returncode == 0 and _xonsh_manager_init.stdout:
            XSH.builtins.execx(_xonsh_manager_init.stdout, "exec", XSH.ctx, filename=_xonsh_manager)

del _xonsh_manager
del _xonsh_root_var
