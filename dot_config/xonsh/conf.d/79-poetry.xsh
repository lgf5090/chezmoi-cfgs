import shutil
import subprocess

from xonsh.built_ins import XSH

if shutil.which("poetry") and XSH.env.get("XONSH_INTERACTIVE"):
    _xonsh_poetry_completion = subprocess.run(["poetry", "completions", "xonsh"], capture_output=True, text=True, check=False)
    if _xonsh_poetry_completion.returncode == 0 and _xonsh_poetry_completion.stdout:
        XSH.builtins.execx(_xonsh_poetry_completion.stdout, "exec", XSH.ctx, filename="poetry")
    del _xonsh_poetry_completion
