import subprocess
import sys
from pathlib import Path

from xonsh.built_ins import XSH

_xenv_default("SDKMAN_DIR", Path.home() / ".sdkman")
_xonsh_sdkman_init = Path(str(XSH.env["SDKMAN_DIR"])) / "bin" / "sdkman-init.sh"


def _sdk(args, stdin=None, script=_xonsh_sdkman_init):
    if not script.is_file():
        print(f"sdk: {script} not found", file=sys.stderr)
        return 1
    result = subprocess.run(
        ["bash", "-lc", 'source "$SDKMAN_DIR/bin/sdkman-init.sh" && sdk "$@"', "sdk", *args],
        env=XSH.env.detype(),
        check=False,
    )
    return result.returncode


if _xonsh_sdkman_init.is_file():
    aliases["sdk"] = _sdk

del _xonsh_sdkman_init
