import subprocess
import sys

from xonsh.built_ins import XSH


def _nvd(args, stdin=None):
    env = XSH.env.detype()
    env["NVIM_APPNAME"] = "nvim-dev"
    try:
        return subprocess.run(["nvim", *args], env=env, check=False).returncode
    except FileNotFoundError:
        print("nvd: nvim: command not found", file=sys.stderr)
        return 127


aliases["nvd"] = _nvd
