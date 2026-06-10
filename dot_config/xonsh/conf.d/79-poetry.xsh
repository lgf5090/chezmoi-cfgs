from pathlib import Path

from xonsh.built_ins import XSH

if XSH.env.get("XONSH_INTERACTIVE"):
    for _xonsh_poetry_completion in (
        Path(XSH.env.get("XDG_DATA_HOME", Path.home() / ".local" / "share")) / "xonsh" / "completions" / "poetry.xsh",
        Path.home() / ".local" / "share" / "xonsh" / "completions" / "poetry.xsh",
        Path(str(XSH.env.get("HOMEBREW_PREFIX", ""))) / "share" / "xonsh" / "completions" / "poetry.xsh"
        if XSH.env.get("HOMEBREW_PREFIX")
        else None,
        Path("/home/linuxbrew/.linuxbrew/share/xonsh/completions/poetry.xsh"),
        Path("/opt/homebrew/share/xonsh/completions/poetry.xsh"),
        Path("/usr/local/share/xonsh/completions/poetry.xsh"),
        Path("/usr/share/xonsh/completions/poetry.xsh"),
    ):
        if _xonsh_poetry_completion and _xonsh_poetry_completion.is_file():
            source @(str(_xonsh_poetry_completion))
            break

    del _xonsh_poetry_completion
