import subprocess
import sys

from xonsh.built_ins import XSH


def _nvl(args, stdin=None):
    env = XSH.env.detype()
    env["NVIM_APPNAME"] = "nvim-lite"
    try:
        return subprocess.run(["nvim", *args], env=env, check=False).returncode
    except FileNotFoundError:
        print("nvl: nvim: command not found", file=sys.stderr)
        return 127


aliases["nvl"] = _nvl
