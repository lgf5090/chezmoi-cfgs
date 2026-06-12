import secrets
import sys

from xonsh.built_ins import XSH


_RANDSTR_OPTIONS = (
    "-h", "--help", "-l", "--length", "-n", "--count", "--lower", "--upper",
    "--alpha", "--digits", "--alnum", "--hex", "--safe", "--symbols",
    "--alphabet", "--prefix", "--suffix",
)
_RANDSTR_LENGTHS = ("8", "12", "16", "24", "32", "48", "64")
_RANDSTR_COUNTS = ("1", "2", "3", "5", "10", "20", "50", "100")


def _randstr_usage():
    print(
        """usage:
  randstr [LENGTH] [COUNT]
  randstr -l LENGTH -n COUNT [options]
  randstr -h | --help

Generate random strings using xonsh/Python built-in runtime features.

options:
  -l, --length N        characters per string, default: 16
  -n, --count N         number of strings, default: 1
  --lower               use a-z
  --upper               use A-Z
  --alpha               use A-Za-z
  --digits              use 0-9
  --alnum               use A-Za-z0-9, default
  --hex                 use 0-9a-f
  --safe                use A-Za-z0-9_-
  --symbols             use shell-friendly symbols
  --alphabet CHARS      use a custom character set
  --prefix TEXT         prepend TEXT to each string
  --suffix TEXT         append TEXT to each string"""
    )


def _randstr_positive_int(value, label):
    try:
        number = int(value)
    except ValueError as exc:
        raise ValueError(f"randstr: {label} requires a positive integer") from exc
    if number < 1:
        raise ValueError(f"randstr: {label} requires a positive integer")
    return number


def _randstr_need_value(args, index, option, label):
    if index + 1 >= len(args):
        raise ValueError(f"randstr: {option} requires {label}")
    return args[index + 1]


def _randstr_apply_positional(value, position):
    if position == 0:
        return "length", _randstr_positive_int(value, "LENGTH")
    if position == 1:
        return "count", _randstr_positive_int(value, "COUNT")
    raise ValueError(f"randstr: unexpected argument: {value}")


def _randstr_one(length, alphabet, prefix="", suffix=""):
    return f"{prefix}{''.join(secrets.choice(alphabet) for _ in range(length))}{suffix}"


def _randstr(args, stdin=None):
    args = list(args)
    length = 16
    count = 1
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    prefix = ""
    suffix = ""
    positional = 0

    try:
        index = 0
        while index < len(args):
            arg = args[index]
            if arg in ("-h", "--help"):
                _randstr_usage()
                return 0
            if arg in ("-l", "--length"):
                length = _randstr_positive_int(_randstr_need_value(args, index, arg, "a positive integer"), arg)
                index += 2
                continue
            if arg in ("-n", "--count"):
                count = _randstr_positive_int(_randstr_need_value(args, index, arg, "a positive integer"), arg)
                index += 2
                continue
            if arg == "--lower":
                alphabet = "abcdefghijklmnopqrstuvwxyz"
                index += 1
                continue
            if arg == "--upper":
                alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                index += 1
                continue
            if arg == "--alpha":
                alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
                index += 1
                continue
            if arg == "--digits":
                alphabet = "0123456789"
                index += 1
                continue
            if arg == "--alnum":
                alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
                index += 1
                continue
            if arg == "--hex":
                alphabet = "0123456789abcdef"
                index += 1
                continue
            if arg == "--safe":
                alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"
                index += 1
                continue
            if arg == "--symbols":
                alphabet = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
                index += 1
                continue
            if arg == "--alphabet":
                alphabet = _randstr_need_value(args, index, arg, "CHARS")
                if not alphabet:
                    raise ValueError("randstr: --alphabet requires CHARS")
                index += 2
                continue
            if arg == "--prefix":
                prefix = _randstr_need_value(args, index, arg, "TEXT")
                index += 2
                continue
            if arg == "--suffix":
                suffix = _randstr_need_value(args, index, arg, "TEXT")
                index += 2
                continue
            if arg == "--":
                for value in args[index + 1:]:
                    name, parsed = _randstr_apply_positional(value, positional)
                    if name == "length":
                        length = parsed
                    else:
                        count = parsed
                    positional += 1
                break
            if arg.startswith("-"):
                raise ValueError(f"randstr: unknown option: {arg}")

            name, parsed = _randstr_apply_positional(arg, positional)
            if name == "length":
                length = parsed
            else:
                count = parsed
            positional += 1
            index += 1

        if not alphabet:
            raise ValueError("randstr: alphabet must not be empty")

        for _ in range(count):
            print(_randstr_one(length, alphabet, prefix, suffix))
        return 0
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2


def _randstr_filter(candidates, prefix):
    return {candidate for candidate in candidates if candidate.startswith(prefix)}


def _randstr_completion(context):
    command = getattr(context, "command", None)
    if command is None or not command.completing_command("randstr"):
        return None

    current = command.prefix
    completed = [arg.value for arg in command.args[1:command.arg_index]]
    previous = completed[-1] if completed else ""

    if previous in ("-l", "--length"):
        return _randstr_filter(_RANDSTR_LENGTHS, current)
    if previous in ("-n", "--count"):
        return _randstr_filter(_RANDSTR_COUNTS, current)
    if previous in ("--alphabet", "--prefix", "--suffix"):
        return None

    return _randstr_filter(_RANDSTR_OPTIONS, current)


aliases["randstr"] = _randstr
_randstr_completion.contextual = True
XSH.completers["randstr"] = _randstr_completion
