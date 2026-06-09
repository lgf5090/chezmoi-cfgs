_MCC_IMPL_LOADED = False


def _mcc_load_impl():
    global _MCC_IMPL_LOADED
    if _MCC_IMPL_LOADED:
        return
    source @($XONSH_CONFIG_DIR + "/lib/mcc.xsh")
    _MCC_IMPL_LOADED = True


def _mcc(args, stdin=None):
    _mcc_load_impl()
    return aliases["mcc"](args, stdin=stdin)


aliases["mcc"] = _mcc
