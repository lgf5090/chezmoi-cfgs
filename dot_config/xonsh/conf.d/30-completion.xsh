from pathlib import Path

from xonsh.built_ins import XSH

_xonsh_bash_completions = [
    Path("/usr/share/bash-completion/bash_completion"),
    Path("/etc/bash_completion"),
    Path("/opt/homebrew/etc/profile.d/bash_completion.sh"),
    Path("/usr/local/etc/profile.d/bash_completion.sh"),
]

_xonsh_bash_completion_files = [str(path) for path in _xonsh_bash_completions if path.is_file()]
if _xonsh_bash_completion_files:
    XSH.env["BASH_COMPLETIONS"] = _xonsh_bash_completion_files

del _xonsh_bash_completions
del _xonsh_bash_completion_files
