import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from xonsh.aliases import EXEC_ALIAS_RE, isexpression, strip_simple_quotes
from xonsh.built_ins import XSH

_XLOCAL_LOADER_VERSION = 4
_XENV_KEY_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
_XALIAS_NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*$")

if XSH.builtins.execx is not None:
    XSH.ctx.setdefault("execx", XSH.builtins.execx)


def _xenv_default(name, value):
    if not XSH.env.get(name):
        XSH.env[name] = str(value)


def _xpath_as_list(value=None):
    if value is None:
        value = XSH.env.get("PATH", [])
    if value is None:
        return []
    if isinstance(value, (str, bytes)):
        return [part for part in os.fsdecode(value).split(os.pathsep) if part]
    return [str(part) for part in value if str(part)]


def _xpath_set(parts):
    XSH.env["PATH"] = [str(part) for part in parts if str(part)]


def _xpath_existing(directory):
    if directory is None:
        return None
    path = os.path.expanduser(str(directory))
    return path if path and os.path.isdir(path) else None


def _xpath_remove(directory):
    directory = str(directory)
    _xpath_set([part for part in _xpath_as_list() if part != directory])


def _xpath_prepend(*directories):
    parts = _xpath_as_list()
    new_parts = []
    seen = set()
    for directory in directories:
        directory = _xpath_existing(directory)
        if directory is None or directory in seen:
            continue
        seen.add(directory)
        new_parts.append(directory)
    if new_parts:
        _xpath_set([*reversed(new_parts), *[part for part in parts if part not in seen]])


def _xpath_append(*directories):
    parts = _xpath_as_list()
    new_parts = []
    seen = set()
    for directory in directories:
        directory = _xpath_existing(directory)
        if directory is None or directory in seen:
            continue
        seen.add(directory)
        new_parts.append(directory)
    if new_parts:
        _xpath_set([*[part for part in parts if part not in seen], *new_parts])


def _xpath_prepend_value(value):
    old_parts = _xpath_as_list()
    new_parts = []
    seen = set()
    for part in str(value).split(os.pathsep) + old_parts:
        if not part or part in seen or not os.path.isdir(part):
            continue
        seen.add(part)
        new_parts.append(part)
    _xpath_set(new_parts)


def _xver_ge(version, minimum):
    def _parts(value):
        parts = []
        for item in str(value).split(".")[:3]:
            match = re.match(r"\d+", item)
            parts.append(int(match.group(0)) if match else 0)
        while len(parts) < 3:
            parts.append(0)
        return parts

    return _parts(version) >= _parts(minimum)


def _xload_envs(file_path):
    path = Path(os.path.expanduser(str(file_path)))
    if not path.is_file():
        return

    for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:].strip()
        if "=" not in line:
            continue

        key, value = line.split("=", 1)
        key = key.rstrip()
        value = value.strip()
        if not _XENV_KEY_RE.match(key):
            continue
        if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
            value = value[1:-1]

        value = value.replace("{HOME}", str(Path.home()))
        value = value.replace("{PATH}", os.pathsep.join(_xpath_as_list()))

        if key == "PATH":
            _xpath_prepend_value(value)
        else:
            XSH.env[key] = value


def _xload_aliases(file_path):
    path = Path(os.path.expanduser(str(file_path)))
    if not path.is_file():
        return

    stat = path.stat()
    cache_path = _xaliases_cache_path(path)
    loaded_aliases = _xload_aliases_cache(cache_path, path, stat)
    if loaded_aliases is not None:
        aliases.update(loaded_aliases)
        return

    loaded_aliases = {}
    cache_entries = []
    for raw_line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        name, body = line.split("=", 1)
        name = name.rstrip()
        body = body.strip()
        if not _XALIAS_NAME_RE.match(name):
            continue
        if len(body) >= 2 and body[0] == body[-1] and body[0] in ("'", '"'):
            body = body[1:-1]

        value = _xparse_alias_value(body)
        loaded_aliases[name] = value
        cache_entries.append([name, "argv" if isinstance(value, list) else "text", value])

    if loaded_aliases:
        aliases.update(loaded_aliases)
        _xwrite_aliases_cache(cache_path, path, stat, cache_entries)


def _xaliases_cache_path(path):
    cache_root = Path(XSH.env.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "xonsh" / "local-aliases"
    safe_name = re.sub(r"[^A-Za-z0-9_.-]+", "_", str(path.resolve()).strip(os.sep))
    return cache_root / f"{safe_name}.json"


def _xparse_alias_value(value):
    try:
        if EXEC_ALIAS_RE.search(value) is None and isexpression(value):
            lexer = XSH.execer.parser.lexer
            return list(map(strip_simple_quotes, lexer.split(value)))
    except Exception:
        return value
    return value


def _xload_aliases_cache(cache_path, path, stat):
    try:
        data = json.loads(cache_path.read_text(encoding="utf-8"))
    except Exception:
        return None

    if (
        data.get("version") != _XLOCAL_LOADER_VERSION
        or data.get("path") != str(path)
        or data.get("mtime_ns") != stat.st_mtime_ns
        or data.get("size") != stat.st_size
    ):
        return None

    loaded_aliases = {}
    for entry in data.get("aliases", []):
        if not isinstance(entry, list) or len(entry) != 3:
            return None
        name, kind, value = entry
        if not isinstance(name, str) or not _XALIAS_NAME_RE.match(name):
            return None
        if kind == "argv" and isinstance(value, list) and all(isinstance(item, str) for item in value):
            loaded_aliases[name] = value
        elif kind == "text" and isinstance(value, str):
            loaded_aliases[name] = value
        else:
            return None

    return loaded_aliases


def _xwrite_aliases_cache(cache_path, path, stat, cache_entries):
    try:
        cache_path.parent.mkdir(parents=True, exist_ok=True)
        cache_path.write_text(
            json.dumps(
                {
                    "version": _XLOCAL_LOADER_VERSION,
                    "path": str(path),
                    "mtime_ns": stat.st_mtime_ns,
                    "size": stat.st_size,
                    "aliases": cache_entries,
                },
                ensure_ascii=False,
                separators=(",", ":"),
            )
            + "\n",
            encoding="utf-8",
        )
    except Exception:
        pass


def _xsource_file(file_path):
    path = Path(file_path)
    source = path.read_text(encoding="utf-8", errors="ignore")
    if not source.endswith("\n"):
        source += "\n"

    ctx = XSH.ctx
    old_file = ctx.get("__file__")
    old_name = ctx.get("__name__")
    had_file = "__file__" in ctx
    had_name = "__name__" in ctx
    ctx["__file__"] = str(path)
    ctx["__name__"] = str(path.resolve())
    try:
        XSH.builtins.execx(source, "exec", ctx, filename=str(path))
    finally:
        if had_file:
            ctx["__file__"] = old_file
        else:
            ctx.pop("__file__", None)
        if had_name:
            ctx["__name__"] = old_name
        else:
            ctx.pop("__name__", None)


_xenv_default("XONSH_PLUGIN_DIR", Path(XSH.env.get("XDG_DATA_HOME", Path.home() / ".local" / "share")) / "xonsh" / "plugins")
_xenv_default("XONSH_PLUGIN_AUTO_INSTALL", "1")
_XPLUGIN_LOADED = globals().get("_XPLUGIN_LOADED", set())


def _xplugin(owner, repo):
    if not owner or not repo:
        print("usage: _xplugin <owner> <repo>", file=sys.stderr)
        return 2

    if repo in _XPLUGIN_LOADED:
        return 0

    plugin_dir = Path(XSH.env["XONSH_PLUGIN_DIR"]) / repo
    if not plugin_dir.is_dir():
        if str(XSH.env.get("XONSH_PLUGIN_AUTO_INSTALL", "1")) != "1":
            print(f"xonsh: plugin missing, skip {repo}", file=sys.stderr)
            return 0
        if shutil.which("git") is None:
            print(f"xonsh: git not found, skip {repo}", file=sys.stderr)
            return 1
        plugin_dir.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(
            ["git", "clone", "--depth=1", f"https://github.com/{owner}/{repo}", str(plugin_dir)],
            check=False,
        )
        if result.returncode != 0:
            print(f"xonsh: failed to install {repo}", file=sys.stderr)
            return 1

    entries = [
        plugin_dir / f"{repo}.xsh",
        plugin_dir / f"{repo}.py",
        *sorted(plugin_dir.glob("*.xsh")),
        *sorted(plugin_dir.glob("*.py")),
    ]
    for entry in entries:
        if entry.is_file():
            _xsource_file(entry)
            _XPLUGIN_LOADED.add(repo)
            return 0

    print(f"xonsh: no plugin entry found for {repo}", file=sys.stderr)
    return 1


def _xplugin_update(args, stdin=None):
    if args:
        print("usage: xplugin-update", file=sys.stderr)
        return 2
    if shutil.which("git") is None:
        print("xonsh: git not found", file=sys.stderr)
        return 1

    plugin_root = Path(XSH.env["XONSH_PLUGIN_DIR"])
    if not plugin_root.is_dir():
        return 0
    for plugin_dir in sorted(plugin_root.iterdir()):
        if not (plugin_dir / ".git").is_dir():
            continue
        print(f"Updating {plugin_dir.name}...")
        subprocess.run(["git", "-C", str(plugin_dir), "pull", "--ff-only"], check=False)


aliases["xplugin-update"] = _xplugin_update
