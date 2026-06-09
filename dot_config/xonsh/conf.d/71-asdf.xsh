from pathlib import Path

from xonsh.built_ins import XSH

if XSH.env.get("ASDF_DIR"):
    _xpath_prepend(Path(str(XSH.env["ASDF_DIR"])) / "bin")

if XSH.env.get("ASDF_DATA_DIR"):
    _xpath_prepend(Path(str(XSH.env["ASDF_DATA_DIR"])) / "shims")
