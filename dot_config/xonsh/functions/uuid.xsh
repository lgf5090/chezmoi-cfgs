import sys
import uuid as _uuid_module

from xonsh.built_ins import XSH


_UUID_OPTIONS = ("-h", "--help", "-n", "--count")
_UUID_COUNTS = ("1", "2", "3", "5", "10", "20", "50", "100")


def _uuid_usage():
    print(
        """usage:
  uuid
  uuid -n COUNT
  uuid -h | --help

Generate RFC 4122 version 4 UUIDs using xonsh/Python built-in runtime features."""
    )


def _uuid(args, stdin=None):
    count = 1
    index = 0
    args = list(args)

    try:
        while index < len(args):
            arg = args[index]
            if arg in ("-h", "--help"):
                _uuid_usage()
                return 0
            if arg in ("-n", "--count"):
                if index + 1 >= len(args):
                    raise ValueError(f"uuid: {arg} requires a positive integer")
                count = int(args[index + 1])
                if count < 1:
                    raise ValueError(f"uuid: {arg} requires a positive integer")
                index += 2
                continue
            if arg == "--":
                if index + 1 < len(args):
                    raise ValueError(f"uuid: unexpected argument: {args[index + 1]}")
                break
            if arg.startswith("-"):
                raise ValueError(f"uuid: unknown option: {arg}")
            raise ValueError(f"uuid: unexpected argument: {arg}")

        for _ in range(count):
            print(_uuid_module.uuid4())
        return 0
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2


def _uuid_filter(candidates, prefix):
    return {candidate for candidate in candidates if candidate.startswith(prefix)}


def _uuid_completion(context):
    command = getattr(context, "command", None)
    if command is None or not command.completing_command("uuid"):
        return None

    current = command.prefix
    completed = [arg.value for arg in command.args[1:command.arg_index]]
    previous = completed[-1] if completed else ""

    if previous in ("-n", "--count"):
        return _uuid_filter(_UUID_COUNTS, current)

    return _uuid_filter(_UUID_OPTIONS, current)


aliases["uuid"] = _uuid
_uuid_completion.contextual = True
XSH.completers["uuid"] = _uuid_completion
