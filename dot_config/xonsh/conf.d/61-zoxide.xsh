import os
import shutil
import subprocess
import sys

import xonsh.dirstack
from xonsh.built_ins import XSH

_xonsh_zoxide_exe = shutil.which("zoxide")


def _xonsh_zoxide_env():
    return XSH.env.detype()


def _xonsh_zoxide_pwd():
    pwd = XSH.env.get("PWD")
    if pwd is None:
        raise RuntimeError("$PWD not found")
    return str(pwd)


def _xonsh_zoxide_cd(path=None):
    if path is None:
        args = []
    elif isinstance(path, bytes):
        args = [path.decode("utf-8")]
    else:
        args = [path]
    _, exc, _ = xonsh.dirstack.cd(args)
    if exc is not None:
        raise RuntimeError(exc)


class _XonshZoxideSilent(Exception):
    pass


def _xonsh_zoxide_errhandler(func):
    def wrapper(args):
        try:
            func(args)
            return 0
        except _XonshZoxideSilent:
            return 1
        except Exception as exc:
            print(f"zoxide: {exc}", file=sys.stderr)
            return 1

    return wrapper


if _xonsh_zoxide_exe and XSH.env.get("XONSH_INTERACTIVE"):
    if "__zoxide_hook" not in globals() and "_xonsh_zoxide_hook" not in globals():

        @XSH.builtins.events.on_chdir
        def _xonsh_zoxide_hook(**_kwargs):
            subprocess.run([_xonsh_zoxide_exe, "add", "--", _xonsh_zoxide_pwd()], check=False, env=_xonsh_zoxide_env())

    @_xonsh_zoxide_errhandler
    def _xonsh_z(args):
        if args == []:
            _xonsh_zoxide_cd()
        elif args == ["-"]:
            _xonsh_zoxide_cd("-")
        elif len(args) == 1 and os.path.isdir(args[0]):
            _xonsh_zoxide_cd(args[0])
        else:
            try:
                result = subprocess.run(
                    [_xonsh_zoxide_exe, "query", "--exclude", _xonsh_zoxide_pwd(), "--", *args],
                    check=True,
                    env=_xonsh_zoxide_env(),
                    stdout=subprocess.PIPE,
                )
            except subprocess.CalledProcessError as exc:
                raise _XonshZoxideSilent() from exc
            _xonsh_zoxide_cd(result.stdout[:-1])

    @_xonsh_zoxide_errhandler
    def _xonsh_zi(args):
        try:
            result = subprocess.run(
                [_xonsh_zoxide_exe, "query", "-i", "--", *args],
                check=True,
                env=_xonsh_zoxide_env(),
                stdout=subprocess.PIPE,
            )
        except subprocess.CalledProcessError as exc:
            raise _XonshZoxideSilent() from exc
        _xonsh_zoxide_cd(result.stdout[:-1])

    aliases["z"] = _xonsh_z
    aliases["zi"] = _xonsh_zi
