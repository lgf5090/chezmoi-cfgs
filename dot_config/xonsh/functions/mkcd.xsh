import sys
from pathlib import Path

from xonsh.dirstack import cd as _xonsh_cd


def _mkcd(args, stdin=None):
    if len(args) != 1:
        print("usage: mkcd <dir>", file=sys.stderr)
        return 2

    target = Path(args[0]).expanduser()
    target.mkdir(parents=True, exist_ok=True)
    return _xonsh_cd([str(target)], stdin=stdin)


aliases["mkcd"] = _mkcd
