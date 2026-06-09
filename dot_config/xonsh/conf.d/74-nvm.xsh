import subprocess
import sys
from pathlib import Path

from xonsh.built_ins import XSH

_xenv_default("NVM_DIR", Path.home() / ".nvm")
_xonsh_nvm_script = Path(str(XSH.env["NVM_DIR"])) / "nvm.sh"


def _xonsh_nvm_bash(command, script=_xonsh_nvm_script):
    def _run(args, stdin=None):
        if not script.is_file():
            print(f"nvm: {script} not found", file=sys.stderr)
            return 1
        result = subprocess.run(
            ["bash", "-lc", f'source "$NVM_DIR/nvm.sh" && {command} "$@"', command, *args],
            env=XSH.env.detype(),
            check=False,
        )
        return result.returncode

    return _run


if _xonsh_nvm_script.is_file():
    aliases["nvm"] = _xonsh_nvm_bash("nvm")
    aliases["node"] = _xonsh_nvm_bash("node")
    aliases["npm"] = _xonsh_nvm_bash("npm")
    aliases["npx"] = _xonsh_nvm_bash("npx")

del _xonsh_nvm_script
