from xonsh.built_ins import XSH

_XONSH_CONDA_IMPL_LOADED = False
_xonsh_conda_discovery = str(XSH.env.get("XONSH_CONDA_DISCOVERY", XSH.env.get("BASH_CONDA_DISCOVERY", "0"))) == "1"


def _xonsh_conda_load_impl():
    global _XONSH_CONDA_IMPL_LOADED
    if _XONSH_CONDA_IMPL_LOADED:
        return
    source @($XONSH_CONFIG_DIR + "/lib/conda.xsh")
    _XONSH_CONDA_IMPL_LOADED = True


def _xonsh_conda_lazy_alias(name):
    def _run(args, stdin=None):
        _xonsh_conda_load_impl()
        target = aliases.get(name)
        if target is None or target is _run:
            return 127
        if callable(target):
            return target(args, stdin=stdin)
        if isinstance(target, (list, tuple)) and target and callable(target[0]):
            if getattr(target[0], "func", None) is _run:
                return 127
            return target[0]([*target[1:], *args], stdin=stdin)

        import subprocess
        command = [*target, *args] if isinstance(target, (list, tuple)) else [target, *args]
        return subprocess.run(command, env=XSH.env.detype(), check=False).returncode

    return _run


if XSH.env.get("ANACONDA_HOME") or _xonsh_conda_discovery:
    aliases["conda"] = _xonsh_conda_lazy_alias("conda")
    aliases["mamba"] = _xonsh_conda_lazy_alias("mamba")

if XSH.env.get("MICROMAMBA_EXE") or _xonsh_conda_discovery:
    aliases["micromamba"] = _xonsh_conda_lazy_alias("micromamba")

del _xonsh_conda_discovery
