import shutil
import subprocess

from prompt_toolkit.application import run_in_terminal

from xonsh.built_ins import XSH
from xonsh.events import events

if shutil.which("fd"):
    XSH.env["FZF_DEFAULT_COMMAND"] = "fd --type f --hidden --strip-cwd-prefix"
else:
    XSH.env["FZF_DEFAULT_COMMAND"] = "find . -type f"

XSH.env["FZF_CTRL_T_COMMAND"] = XSH.env["FZF_DEFAULT_COMMAND"]
XSH.env["FZF_DEFAULT_OPTS"] = "--height=60% --layout=reverse --border=rounded --preview-window=right:65%:wrap:border-left"

if shutil.which("bat"):
    XSH.env["_FZF_PREVIEW_CMD"] = "bat --color=always --style=plain,numbers --line-range=:500 {}"
else:
    XSH.env["_FZF_PREVIEW_CMD"] = 'sed -n "1,200p" {} 2>/dev/null'

XSH.env["FZF_CTRL_T_OPTS"] = f"--preview '{XSH.env['_FZF_PREVIEW_CMD']}'"


def _xonsh_fzf_file_no_hidden():
    if shutil.which("fd"):
        finder = subprocess.run(["fd", "--type", "f", "--strip-cwd-prefix"], capture_output=True, text=True, check=False)
        candidates = finder.stdout
    else:
        finder = subprocess.run(["find", ".", "-type", "f", "!", "-path", "*/.*"], capture_output=True, text=True, check=False)
        candidates = "\n".join(line[2:] if line.startswith("./") else line for line in finder.stdout.splitlines())
    if not candidates:
        return ""

    fzf = subprocess.run(
        ["fzf", "--preview", str(XSH.env["_FZF_PREVIEW_CMD"])],
        input=candidates,
        capture_output=True,
        text=True,
        check=False,
    )
    if fzf.returncode != 0:
        return ""
    return fzf.stdout.rstrip("\n")


if shutil.which("fzf"):
    @events.on_ptk_create
    def _xonsh_fzf_bindings(bindings=None, **_kwargs):
        if bindings is None:
            return

        @bindings.add("c-f")
        def _xonsh_fzf_insert_file(event):
            buffer = event.current_buffer

            def _insert_selection():
                result = _xonsh_fzf_file_no_hidden()
                if result:
                    buffer.insert_text(result)

            run_in_terminal(_insert_selection)
