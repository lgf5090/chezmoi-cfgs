import sys

from xonsh.built_ins import XSH


def _paths(args, stdin=None):
    if args:
        print("usage: paths", file=sys.stderr)
        return 2

    for part in XSH.env.get("PATH", []):
        print(part)


aliases["paths"] = _paths
