from prompt_toolkit.key_binding.bindings.named_commands import get_by_name

from xonsh.events import events


@events.on_ptk_create
def _xonsh_keybindings(bindings=None, **_kwargs):
    if bindings is None:
        return

    for _xonsh_keys, _xonsh_command in (
        (("c-right",), "forward-word"),
        (("c-left",), "backward-word"),
        (("c-a",), "beginning-of-line"),
        (("c-e",), "end-of-line"),
    ):
        try:
            bindings.add(*_xonsh_keys)(get_by_name(_xonsh_command))
        except Exception:
            pass
