import shutil
import subprocess
import os
from pathlib import Path

from xonsh.built_ins import XSH

if XSH.env.get("XONSH_INTERACTIVE") and not XSH.env.get("SHELLS_NO_PROMPT"):
    if shutil.which("starship"):
        _xonsh_starship = subprocess.run(["starship", "init", "xonsh"], capture_output=True, text=True, check=False)
        if _xonsh_starship.returncode == 0 and _xonsh_starship.stdout:
            XSH.builtins.execx(_xonsh_starship.stdout, "exec", XSH.ctx, filename="starship")
        del _xonsh_starship
    else:
        def _xonsh_prompt_env():
            if XSH.env.get("VIRTUAL_ENV"):
                return f" ({Path(str(XSH.env['VIRTUAL_ENV'])).name})"
            if XSH.env.get("CONDA_DEFAULT_ENV") and XSH.env.get("CONDA_DEFAULT_ENV") != "base":
                return f" ({XSH.env['CONDA_DEFAULT_ENV']})"
            return ""


        def _xonsh_prompt_git():
            if not shutil.which("git"):
                return ""
            cwd = Path(str(XSH.env.get("PWD", Path.cwd())))
            for directory in (cwd, *cwd.parents):
                if not (directory / ".git").exists():
                    continue
                branch = subprocess.run(
                    ["git", "symbolic-ref", "--short", "HEAD"],
                    cwd=str(directory),
                    capture_output=True,
                    text=True,
                    check=False,
                )
                branch_name = branch.stdout.strip()
                if not branch_name:
                    branch = subprocess.run(
                        ["git", "rev-parse", "--short", "HEAD"],
                        cwd=str(directory),
                        capture_output=True,
                        text=True,
                        check=False,
                    )
                    branch_name = branch.stdout.strip()
                if not branch_name:
                    return ""
                dirty = subprocess.run(
                    ["git", "diff-index", "--quiet", "HEAD", "--"],
                    cwd=str(directory),
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False,
                )
                return f" {branch_name}{'*' if dirty.returncode != 0 else ''}"
            return ""


        def _xonsh_prompt_rc():
            code = XSH.env["PROMPT_FIELDS"].pick("last_return_code")
            return f" [{code}]" if code else ""


        def _xonsh_prompt_end():
            return "#" if hasattr(os, "geteuid") and os.geteuid() == 0 else "$"


        XSH.env["PROMPT_FIELDS"]["shells_env"] = _xonsh_prompt_env
        XSH.env["PROMPT_FIELDS"]["shells_git"] = _xonsh_prompt_git
        XSH.env["PROMPT_FIELDS"]["shells_rc"] = _xonsh_prompt_rc
        XSH.env["PROMPT_FIELDS"]["shells_prompt_end"] = _xonsh_prompt_end
        XSH.env["PROMPT_FIELDS"]["time_format"] = "%H:%M:%S"
        XSH.env["PROMPT"] = (
            "{INTENSE_BLACK}[{localtime}]{RESET} "
            "{GREEN}{user}{BOLD_WHITE}@{hostname}{RESET} "
            "{BLUE}[{cwd}]{RESET}"
            "{CYAN}{shells_env}{RESET}"
            "{PURPLE}{shells_git}{RESET}"
            "{RED}{shells_rc}{RESET}\n"
            "{CYAN}{shells_prompt_end}{RESET} "
        )
