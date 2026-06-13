import os
import shlex
import shutil
import subprocess
import sys

from xonsh.built_ins import XSH


_SPM_UNIX_MANAGERS = [
    "brew",
    "apt", "apt-get", "nala",
    "dnf", "dnf5", "yum", "microdnf",
    "apk", "pacman", "paru", "yay", "zypper",
    "xbps-install", "emerge", "eopkg", "swupd",
    "pkg", "pkg_add", "pkgin", "port",
    "nix-env", "profile", "nix", "guix", "conda",
]
_SPM_WINDOWS_MANAGERS = ["winget", "scoop", "choco"]
_SPM_SUDO_MANAGERS = {
    "apt", "apt-get", "nala", "dnf", "dnf5", "yum", "microdnf", "apk",
    "pacman", "zypper", "xbps-install", "emerge", "eopkg", "swupd",
    "pkg", "pkg_add", "port",
}


def _spm_help():
    print("""spm - simple cross-platform package manager helper

USAGE
  spm [package ...]
  spm -i | --install package ...
  spm -u | --upgrade [package ...]
  spm -s | --search query
  spm -r | --remove package ...
  spm --info package
  spm --list [query]
  spm --update
  spm --clean
  spm --manager NAME action [package ...]
  spm --dry-run action [package ...]
  spm -h | --help

DEFAULTS
  spm git
      Install git. On Debian/Ubuntu this runs: sudo apt install -y git

  spm -i git
  spm --install git
      Install git.

  spm -u git
  spm --upgrade git
      Upgrade git.

  spm -u
  spm --upgrade
      Upgrade all packages. On Debian/Ubuntu this runs:
        sudo apt update && sudo apt upgrade -y

  spm -s git
  spm --search git
      Search package names/descriptions.

MORE EXAMPLES
  spm --remove git
  spm --info git
  spm --list git
  spm --update
  spm --clean
  spm --which
  spm --dry-run -u
  spm -m apt install curl
  spm --manager brew search ripgrep

PACKAGE MANAGER PRIORITY
  Unix, Linux, macOS, WSL, WSL2:
    brew first, then system managers such as apt, dnf, yum, apk, pacman,
    zypper, xbps-install, emerge, eopkg, swupd, pkg, pkg_add, pkgin,
    port, nix, guix, and conda.

  Windows shells:
    winget, then scoop, then choco.

OPTIONS
  -i, --install       install packages
  -u, --upgrade       upgrade packages, or all packages when no package is given
  -s, --search        search packages
  -r, --remove        remove packages
      --info          show package details
  -l, --list          list installed packages, optionally filtered by query
      --update        refresh package indexes
      --clean         clean package manager caches when supported
      --which         print selected package manager
  -m, --manager NAME  force a package manager for this invocation
      --dry-run       print commands without running them
  -h, --help          show this help

ENVIRONMENT
  SPM_MANAGER         default package manager override, same as --manager
  SPM_NO_SUDO=1       never prepend sudo""")


def _spm_has(name):
    return shutil.which(name) is not None


def _spm_is_windows():
    return os.name == "nt" or sys.platform.startswith(("win32", "cygwin", "msys"))


def _spm_detect_manager():
    env_manager = XSH.env.get("SPM_MANAGER")
    if env_manager:
        return env_manager

    managers = _SPM_WINDOWS_MANAGERS if _spm_is_windows() else _SPM_UNIX_MANAGERS
    for manager in managers:
        if manager == "profile":
            if _spm_has("nix"):
                result = subprocess.run(
                    ["nix", "profile", "--help"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False,
                )
                if result.returncode == 0:
                    return "nix-profile"
            continue

        if _spm_has(manager):
            return manager

    raise RuntimeError("spm: no supported package manager found")


def _spm_require_packages(action, packages):
    if not packages:
        raise RuntimeError(f"spm: {action} requires at least one package/query")


def _spm_unsupported(manager, action):
    raise RuntimeError(f"spm: {manager} does not support action: {action}")


def _spm_join(packages):
    return " ".join(packages)


def _cmd(use_sudo, argv):
    return {"sudo": use_sudo, "argv": argv}


def _spm_build_commands(manager, action, packages):
    if manager in ("apt", "apt-get"):
        if action == "install":
            _spm_require_packages(action, packages)
            return [_cmd(True, [manager, "install", "-y", *packages])]
        if action == "upgrade":
            if not packages:
                return [_cmd(True, [manager, "update"]), _cmd(True, [manager, "upgrade", "-y"])]
            return [_cmd(True, [manager, "install", "--only-upgrade", "-y", *packages])]
        if action == "search":
            _spm_require_packages(action, packages)
            return [_cmd(False, [manager, "search", *packages])]
        if action == "remove":
            _spm_require_packages(action, packages)
            return [_cmd(True, [manager, "remove", "-y", *packages])]
        if action == "info":
            _spm_require_packages(action, packages)
            return [_cmd(False, [manager, "show", *packages])]
        if action == "list":
            return [_cmd(False, [manager, "list", "--installed", *packages])]
        if action == "update":
            return [_cmd(True, [manager, "update"])]
        if action == "clean":
            return [_cmd(True, [manager, "autoremove", "-y"]), _cmd(True, [manager, "autoclean"])]
        _spm_unsupported(manager, action)

    if manager == "nala":
        if action == "install":
            _spm_require_packages(action, packages)
            return [_cmd(True, ["nala", "install", "-y", *packages])]
        if action == "upgrade":
            if not packages:
                return [_cmd(True, ["nala", "update"]), _cmd(True, ["nala", "upgrade", "-y"])]
            return [_cmd(True, ["nala", "install", "--only-upgrade", "-y", *packages])]
        if action == "search":
            _spm_require_packages(action, packages)
            return [_cmd(False, ["nala", "search", *packages])]
        if action == "remove":
            _spm_require_packages(action, packages)
            return [_cmd(True, ["nala", "remove", "-y", *packages])]
        if action == "info":
            _spm_require_packages(action, packages)
            return [_cmd(False, ["nala", "show", *packages])]
        if action == "list":
            return [_cmd(False, ["apt", "list", "--installed", *packages])]
        if action == "update":
            return [_cmd(True, ["nala", "update"])]
        if action == "clean":
            return [_cmd(True, ["apt", "autoremove", "-y"]), _cmd(True, ["apt", "autoclean"])]
        _spm_unsupported(manager, action)

    if manager == "brew":
        table = {
            "install": ["brew", "install"],
            "upgrade": ["brew", "upgrade"],
            "search": ["brew", "search"],
            "remove": ["brew", "uninstall"],
            "info": ["brew", "info"],
            "list": ["brew", "list"],
            "update": ["brew", "update"],
            "clean": ["brew", "cleanup"],
        }
        if action not in table:
            _spm_unsupported(manager, action)
        if action in {"install", "search", "remove", "info"}:
            _spm_require_packages(action, packages)
        return [_cmd(False, table[action] + ([] if action in {"update", "clean"} else packages))]

    if manager in ("dnf", "dnf5", "yum", "microdnf"):
        if action == "install":
            _spm_require_packages(action, packages)
            return [_cmd(True, [manager, "install", "-y", *packages])]
        if action == "upgrade":
            return [_cmd(True, [manager, "upgrade", "-y", *packages])]
        if action == "search":
            _spm_require_packages(action, packages)
            return [_cmd(False, [manager, "search", *packages])]
        if action == "remove":
            _spm_require_packages(action, packages)
            return [_cmd(True, [manager, "remove", "-y", *packages])]
        if action == "info":
            _spm_require_packages(action, packages)
            return [_cmd(False, [manager, "info", *packages])]
        if action == "list":
            return [_cmd(False, [manager, "list", "installed", *packages])]
        if action == "update":
            return [_cmd(True, [manager, "makecache"])]
        if action == "clean":
            return [_cmd(True, [manager, "clean", "all"])]
        _spm_unsupported(manager, action)

    if manager == "apk":
        table = {
            "install": (True, ["apk", "add"], True),
            "upgrade": (True, ["apk", "upgrade"], False),
            "search": (False, ["apk", "search"], True),
            "remove": (True, ["apk", "del"], True),
            "info": (False, ["apk", "info"], True),
            "list": (False, ["apk", "info"], False),
            "update": (True, ["apk", "update"], False),
            "clean": (True, ["apk", "cache", "clean"], False),
        }
        if action not in table:
            _spm_unsupported(manager, action)
        use_sudo, head, required = table[action]
        if required:
            _spm_require_packages(action, packages)
        return [_cmd(use_sudo, head + ([] if action in {"update", "clean"} else packages))]

    if manager == "pacman":
        if action == "install":
            _spm_require_packages(action, packages)
            return [_cmd(True, ["pacman", "-S", "--needed", "--noconfirm", *packages])]
        if action == "upgrade":
            if not packages:
                return [_cmd(True, ["pacman", "-Syu", "--noconfirm"])]
            return [_cmd(True, ["pacman", "-S", "--needed", "--noconfirm", *packages])]
        if action == "search":
            _spm_require_packages(action, packages)
            return [_cmd(False, ["pacman", "-Ss", *packages])]
        if action == "remove":
            _spm_require_packages(action, packages)
            return [_cmd(True, ["pacman", "-Rns", "--noconfirm", *packages])]
        if action == "info":
            _spm_require_packages(action, packages)
            return [_cmd(False, ["pacman", "-Si", *packages])]
        if action == "list":
            return [_cmd(False, ["pacman", "-Qs", *packages])]
        if action == "update":
            return [_cmd(True, ["pacman", "-Sy"])]
        if action == "clean":
            return [_cmd(True, ["pacman", "-Sc", "--noconfirm"])]
        _spm_unsupported(manager, action)

    if manager in ("paru", "yay"):
        if action == "install":
            _spm_require_packages(action, packages)
            return [_cmd(False, [manager, "-S", "--needed", "--noconfirm", *packages])]
        if action == "upgrade":
            if not packages:
                return [_cmd(False, [manager, "-Syu", "--noconfirm"])]
            return [_cmd(False, [manager, "-S", "--needed", "--noconfirm", *packages])]
        if action == "search":
            _spm_require_packages(action, packages)
            return [_cmd(False, [manager, "-Ss", *packages])]
        if action == "remove":
            _spm_require_packages(action, packages)
            return [_cmd(False, [manager, "-Rns", "--noconfirm", *packages])]
        if action == "info":
            _spm_require_packages(action, packages)
            return [_cmd(False, [manager, "-Si", *packages])]
        if action == "list":
            return [_cmd(False, [manager, "-Qs", *packages])]
        if action == "update":
            return [_cmd(False, [manager, "-Sy"])]
        if action == "clean":
            return [_cmd(False, [manager, "-Sc", "--noconfirm"])]
        _spm_unsupported(manager, action)

    if manager == "zypper":
        table = {
            "install": (True, ["zypper", "--non-interactive", "install"], True),
            "upgrade": (True, ["zypper", "--non-interactive", "update"], False),
            "search": (False, ["zypper", "search"], True),
            "remove": (True, ["zypper", "--non-interactive", "remove"], True),
            "info": (False, ["zypper", "info"], True),
            "list": (False, ["zypper", "search", "--installed-only"], False),
            "update": (True, ["zypper", "refresh"], False),
            "clean": (True, ["zypper", "clean", "--all"], False),
        }
        if action not in table:
            _spm_unsupported(manager, action)
        use_sudo, head, required = table[action]
        if required:
            _spm_require_packages(action, packages)
        return [_cmd(use_sudo, head + ([] if action in {"update", "clean"} else packages))]

    if manager == "xbps-install":
        if action == "install":
            _spm_require_packages(action, packages)
            return [_cmd(True, ["xbps-install", "-Sy", *packages])]
        if action == "upgrade":
            if not packages:
                return [_cmd(True, ["xbps-install", "-Syu"])]
            return [_cmd(True, ["xbps-install", "-Su", *packages])]
        if action == "search":
            _spm_require_packages(action, packages)
            return [_cmd(False, ["xbps-query", "-Rs", _spm_join(packages)])]
        if action == "remove":
            _spm_require_packages(action, packages)
            return [_cmd(True, ["xbps-remove", "-R", *packages])]
        if action == "info":
            _spm_require_packages(action, packages)
            return [_cmd(False, ["xbps-query", "-RS", *packages])]
        if action == "list":
            return [_cmd(False, ["xbps-query", "-l", *packages])]
        if action == "update":
            return [_cmd(True, ["xbps-install", "-S"])]
        if action == "clean":
            return [_cmd(True, ["xbps-remove", "-O"])]
        _spm_unsupported(manager, action)

    if manager == "emerge":
        if action == "install":
            _spm_require_packages(action, packages)
            return [_cmd(True, ["emerge", "--ask=n", *packages])]
        if action == "upgrade":
            if not packages:
                return [_cmd(True, ["emerge", "--ask=n", "--update", "--deep", "--newuse", "@world"])]
            return [_cmd(True, ["emerge", "--ask=n", "--update", *packages])]
        if action == "search":
            _spm_require_packages(action, packages)
            return [_cmd(False, ["emerge", "--search", _spm_join(packages)])]
        if action == "remove":
            _spm_require_packages(action, packages)
            return [_cmd(True, ["emerge", "--ask=n", "--depclean", *packages])]
        if action == "info":
            _spm_require_packages(action, packages)
            return [_cmd(False, ["equery", "meta", *packages])]
        if action == "list":
            return [_cmd(False, ["equery", "list", *packages])]
        if action == "update":
            return [_cmd(True, ["emerge", "--sync"])]
        if action == "clean":
            return [_cmd(True, ["emerge", "--ask=n", "--depclean"])]
        _spm_unsupported(manager, action)

    if manager in ("eopkg", "swupd", "pkg", "pkg_add", "pkgin", "port", "winget", "scoop", "choco", "nix-env", "nix-profile", "nix", "guix", "conda"):
        return _spm_build_remaining_commands(manager, action, packages)

    raise RuntimeError(f"spm: unsupported package manager: {manager}")


def _spm_build_remaining_commands(manager, action, packages):
    if manager == "eopkg":
        table = {
            "install": (True, ["eopkg", "install", "-y"], True),
            "upgrade": (True, ["eopkg", "upgrade", "-y"], False),
            "search": (False, ["eopkg", "search"], True),
            "remove": (True, ["eopkg", "remove", "-y"], True),
            "info": (False, ["eopkg", "info"], True),
            "list": (False, ["eopkg", "list-installed"], False),
            "update": (True, ["eopkg", "update-repo"], False),
            "clean": (True, ["eopkg", "clean"], False),
        }
    elif manager == "swupd":
        table = {
            "install": (True, ["swupd", "bundle-add"], True),
            "upgrade": (True, ["swupd", "update"], False),
            "search": (False, ["swupd", "search"], True),
            "remove": (True, ["swupd", "bundle-remove"], True),
            "info": (False, ["swupd", "bundle-info"], True),
            "list": (False, ["swupd", "bundle-list"], False),
            "update": (True, ["swupd", "update", "--download"], False),
            "clean": (True, ["swupd", "clean"], False),
        }
    elif manager == "pkg":
        table = {
            "install": (True, ["pkg", "install", "-y"], True),
            "upgrade": (True, ["pkg", "upgrade", "-y"], False),
            "search": (False, ["pkg", "search"], True),
            "remove": (True, ["pkg", "delete", "-y"], True),
            "info": (False, ["pkg", "info"], True),
            "list": (False, ["pkg", "info"], False),
            "update": (True, ["pkg", "update"], False),
            "clean": (True, ["pkg", "clean", "-y"], False),
        }
    elif manager == "pkg_add":
        if action == "search":
            _spm_require_packages(action, packages)
            return [_cmd(False, ["pkg_info", "-Q", _spm_join(packages)])]
        table = {
            "install": (True, ["pkg_add"], True),
            "upgrade": (True, ["pkg_add", "-u"], False),
            "remove": (True, ["pkg_delete"], True),
            "info": (False, ["pkg_info"], True),
            "list": (False, ["pkg_info"], False),
            "update": (True, ["pkg_add", "-u"], False),
        }
    elif manager == "pkgin":
        table = {
            "install": (True, ["pkgin", "-y", "install"], True),
            "upgrade": (True, ["pkgin", "-y", "upgrade"], False),
            "search": (False, ["pkgin", "search"], True),
            "remove": (True, ["pkgin", "-y", "remove"], True),
            "info": (False, ["pkgin", "show-full-deps"], True),
            "list": (False, ["pkgin", "list"], False),
            "update": (True, ["pkgin", "update"], False),
            "clean": (True, ["pkgin", "clean"], False),
        }
    elif manager == "port":
        if action == "upgrade" and not packages:
            return [_cmd(True, ["port", "selfupdate"]), _cmd(True, ["port", "upgrade", "outdated"])]
        table = {
            "install": (True, ["port", "install"], True),
            "upgrade": (True, ["port", "upgrade"], False),
            "search": (False, ["port", "search"], True),
            "remove": (True, ["port", "uninstall"], True),
            "info": (False, ["port", "info"], True),
            "list": (False, ["port", "installed"], False),
            "update": (True, ["port", "selfupdate"], False),
            "clean": (True, ["port", "clean", "--all", "all"], False),
        }
    elif manager == "winget":
        if action == "upgrade" and not packages:
            return [_cmd(False, ["winget", "upgrade", "--all", "--accept-package-agreements", "--accept-source-agreements"])]
        table = {
            "install": (False, ["winget", "install", "--accept-package-agreements", "--accept-source-agreements"], True),
            "upgrade": (False, ["winget", "upgrade", "--accept-package-agreements", "--accept-source-agreements"], False),
            "search": (False, ["winget", "search"], True),
            "remove": (False, ["winget", "uninstall"], True),
            "info": (False, ["winget", "show"], True),
            "list": (False, ["winget", "list"], False),
            "update": (False, ["winget", "source", "update"], False),
        }
    elif manager == "scoop":
        if action == "upgrade" and not packages:
            return [_cmd(False, ["scoop", "update"]), _cmd(False, ["scoop", "update", "*"])]
        table = {
            "install": (False, ["scoop", "install"], True),
            "upgrade": (False, ["scoop", "update"], False),
            "search": (False, ["scoop", "search"], True),
            "remove": (False, ["scoop", "uninstall"], True),
            "info": (False, ["scoop", "info"], True),
            "list": (False, ["scoop", "list"], False),
            "update": (False, ["scoop", "update"], False),
            "clean": (False, ["scoop", "cleanup", "*"], False),
        }
    elif manager == "choco":
        if action == "upgrade" and not packages:
            return [_cmd(False, ["choco", "upgrade", "all", "-y"])]
        table = {
            "install": (False, ["choco", "install", "-y"], True),
            "upgrade": (False, ["choco", "upgrade", "-y"], False),
            "search": (False, ["choco", "search"], True),
            "remove": (False, ["choco", "uninstall", "-y"], True),
            "info": (False, ["choco", "info"], True),
            "list": (False, ["choco", "list", "--local-only"], False),
            "update": (False, ["choco", "outdated"], False),
        }
    elif manager == "nix-env":
        table = {
            "install": (False, ["nix-env", "-iA"], True),
            "upgrade": (False, ["nix-env", "-u"], False),
            "search": (False, ["nix-env", "-qaP"], True),
            "remove": (False, ["nix-env", "-e"], True),
            "info": (False, ["nix-env", "-qa", "--description"], True),
            "list": (False, ["nix-env", "-q"], False),
            "update": (False, ["nix-channel", "--update"], False),
            "clean": (False, ["nix-collect-garbage", "-d"], False),
        }
    elif manager == "nix-profile":
        if action == "upgrade" and not packages:
            return [_cmd(False, ["nix", "profile", "upgrade", "--all"])]
        if action in {"search", "info"}:
            _spm_require_packages(action, packages)
            return [_cmd(False, ["nix", "search", "nixpkgs", _spm_join(packages)])]
        table = {
            "install": (False, ["nix", "profile", "install"], True),
            "upgrade": (False, ["nix", "profile", "upgrade"], False),
            "remove": (False, ["nix", "profile", "remove"], True),
            "list": (False, ["nix", "profile", "list"], False),
            "clean": (False, ["nix", "store", "gc"], False),
        }
    elif manager == "nix":
        if action in {"search", "info"}:
            _spm_require_packages(action, packages)
            return [_cmd(False, ["nix", "search", "nixpkgs", _spm_join(packages)])]
        table = {
            "list": (False, ["nix", "profile", "list"], False),
            "clean": (False, ["nix", "store", "gc"], False),
        }
    elif manager == "guix":
        table = {
            "install": (False, ["guix", "install"], True),
            "upgrade": (False, ["guix", "upgrade"], False),
            "search": (False, ["guix", "search"], True),
            "remove": (False, ["guix", "remove"], True),
            "info": (False, ["guix", "show"], True),
            "list": (False, ["guix", "package", "--list-installed"], False),
            "update": (False, ["guix", "pull"], False),
            "clean": (False, ["guix", "gc"], False),
        }
    elif manager == "conda":
        if action == "upgrade" and not packages:
            return [_cmd(False, ["conda", "update", "-y", "--all"])]
        table = {
            "install": (False, ["conda", "install", "-y"], True),
            "upgrade": (False, ["conda", "update", "-y"], False),
            "search": (False, ["conda", "search"], True),
            "remove": (False, ["conda", "remove", "-y"], True),
            "info": (False, ["conda", "search", "--info"], True),
            "list": (False, ["conda", "list"], False),
            "update": (False, ["conda", "update", "-y", "conda"], False),
            "clean": (False, ["conda", "clean", "-a", "-y"], False),
        }
    else:
        raise RuntimeError(f"spm: unsupported package manager: {manager}")

    if action not in table:
        _spm_unsupported(manager, action)
    use_sudo, head, required = table[action]
    if required:
        _spm_require_packages(action, packages)
    return [_cmd(use_sudo, head + ([] if action in {"update", "clean"} else packages))]


def _spm_needs_sudo(manager):
    if XSH.env.get("SPM_NO_SUDO") == "1":
        return False
    if manager not in _SPM_SUDO_MANAGERS:
        return False
    if not _spm_has("sudo"):
        return False
    if hasattr(os, "geteuid") and os.geteuid() == 0:
        return False
    return True


def _spm_run_commands(manager, commands, dry_run):
    for command in commands:
        argv = list(command["argv"])
        if command["sudo"] and _spm_needs_sudo(manager):
            argv.insert(0, "sudo")
        if dry_run:
            print("+ " + " ".join(shlex.quote(arg) for arg in argv))
            continue
        result = subprocess.run(argv, check=False)
        if result.returncode != 0:
            return result.returncode
    return 0


def _spm_action_alias(value):
    aliases = {
        "install": "install",
        "add": "install",
        "upgrade": "upgrade",
        "update-all": "upgrade",
        "search": "search",
        "remove": "remove",
        "rm": "remove",
        "uninstall": "remove",
        "info": "info",
        "show": "info",
        "list": "list",
        "ls": "list",
        "refresh": "update",
        "clean": "clean",
    }
    return aliases.get(value, "")


def _spm(args, stdin=None):
    action = "install"
    manager = XSH.env.get("SPM_MANAGER", "")
    dry_run = False
    which = False
    index = 0

    while index < len(args):
        arg = args[index]
        if arg in ("-h", "--help"):
            _spm_help()
            return 0
        if arg == "--which":
            which = True
            index += 1
            continue
        if arg == "--dry-run":
            dry_run = True
            index += 1
            continue
        if arg in ("-m", "--manager"):
            if index + 1 >= len(args):
                print(f"spm: {arg} requires a package manager name", file=sys.stderr)
                return 2
            manager = args[index + 1]
            index += 2
            continue
        if arg.startswith("--manager="):
            manager = arg.split("=", 1)[1]
            index += 1
            continue
        if arg in ("-i", "--install", "install", "add"):
            action = "install"
            index += 1
            continue
        if arg in ("-u", "--upgrade", "upgrade", "update-all"):
            action = "upgrade"
            index += 1
            continue
        if arg in ("-s", "--search", "search"):
            action = "search"
            index += 1
            continue
        if arg in ("-r", "--remove", "remove", "rm", "uninstall"):
            action = "remove"
            index += 1
            continue
        if arg in ("--info", "info", "show"):
            action = "info"
            index += 1
            continue
        if arg in ("-l", "--list", "list", "ls"):
            action = "list"
            index += 1
            continue
        if arg in ("--update", "refresh"):
            action = "update"
            index += 1
            continue
        if arg in ("--clean", "clean"):
            action = "clean"
            index += 1
            continue
        if arg == "--":
            index += 1
            break
        if arg.startswith("-"):
            print(f"spm: unknown option: {arg}", file=sys.stderr)
            print("Run `spm --help` for usage.", file=sys.stderr)
            return 2
        break

    packages = args[index:]
    if packages:
        alias = _spm_action_alias(packages[0])
        if alias:
            action = alias
            packages = packages[1:]

    try:
        if not manager:
            manager = _spm_detect_manager()
        if which:
            print(manager)
            return 0
        commands = _spm_build_commands(manager, action, packages)
        return _spm_run_commands(manager, commands, dry_run)
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 1


aliases["spm"] = _spm
