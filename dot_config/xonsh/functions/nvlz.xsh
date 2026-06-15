import subprocess
import sys

from xonsh.built_ins import XSH


def _nvlz(args, stdin=None):
    env = XSH.env.detype()
    env["NVIM_APPNAME"] = "nvim-lazy"
    try:
        return subprocess.run(["nvim", *args], env=env, check=False).returncode
    except FileNotFoundError:
        print("nvlz: nvim: command not found", file=sys.stderr)
        return 127


aliases["nvlz"] = _nvlz
