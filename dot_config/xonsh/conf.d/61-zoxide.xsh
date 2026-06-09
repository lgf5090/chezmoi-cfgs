import shutil
import subprocess

from xonsh.built_ins import XSH

if shutil.which("zoxide") and XSH.env.get("XONSH_INTERACTIVE"):
    _xonsh_zoxide = subprocess.run(["zoxide", "init", "xonsh"], capture_output=True, text=True, check=False)
    if _xonsh_zoxide.returncode == 0 and _xonsh_zoxide.stdout:
        XSH.builtins.execx(_xonsh_zoxide.stdout, "exec", XSH.ctx, filename="zoxide")
    del _xonsh_zoxide
