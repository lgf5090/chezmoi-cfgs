from xonsh.built_ins import XSH

_MCC_COMPLETION_IMPL_LOADED = False


def _mcc_load_completion_impl():
    global _MCC_COMPLETION_IMPL_LOADED
    if _MCC_COMPLETION_IMPL_LOADED:
        return
    source @($XONSH_CONFIG_DIR + "/lib/mcc_completion.xsh")
    _MCC_COMPLETION_IMPL_LOADED = True


def _mcc_completion_loader(context):
    _mcc_load_completion_impl()
    completer = XSH.completers.get("mcc")
    if completer is _mcc_completion_loader:
        return None
    return completer(context)


_mcc_completion_loader.contextual = True
XSH.completers["mcc"] = _mcc_completion_loader
