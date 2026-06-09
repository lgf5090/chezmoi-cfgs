from xonsh.built_ins import XSH

_xenv_default("EDITOR", "vim")
_xenv_default("VISUAL", XSH.env["EDITOR"])
_xenv_default("PAGER", "less")
_xenv_default("LESS", "-R -F -X")
_xenv_default("CLICOLOR", "1")
