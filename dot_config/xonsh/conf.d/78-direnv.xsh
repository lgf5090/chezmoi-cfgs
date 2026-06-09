import json
import shutil
import subprocess

from xonsh.built_ins import XSH
from xonsh.events import events


def _xonsh_direnv_export():
    result = subprocess.run(["direnv", "export", "json"], capture_output=True, text=True, env=XSH.env.detype(), check=False)
    if result.returncode != 0 or not result.stdout.strip():
        return
    try:
        changes = json.loads(result.stdout)
    except json.JSONDecodeError:
        return
    for name, value in changes.items():
        if value is None:
            XSH.env.pop(name, None)
        else:
            XSH.env[name] = value


if shutil.which("direnv") and XSH.env.get("XONSH_INTERACTIVE"):
    @events.on_chdir
    def _xonsh_direnv_on_chdir(**_kwargs):
        _xonsh_direnv_export()

    @events.on_pre_prompt
    def _xonsh_direnv_on_prompt(**_kwargs):
        _xonsh_direnv_export()
