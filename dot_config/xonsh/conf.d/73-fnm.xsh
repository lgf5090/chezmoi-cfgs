import shutil
import subprocess
from pathlib import Path

from xonsh.built_ins import XSH

if XSH.env.get("FNM_DIR"):
    _xpath_prepend(Path(str(XSH.env["FNM_DIR"])))

if shutil.which("fnm"):
    _xonsh_fnm_env = subprocess.run(["fnm", "env", "--use-on-cd", "--shell", "xonsh"], capture_output=True, text=True, check=False)
    if _xonsh_fnm_env.returncode == 0 and _xonsh_fnm_env.stdout:
        XSH.builtins.execx(_xonsh_fnm_env.stdout, "exec", XSH.ctx, filename="fnm")
