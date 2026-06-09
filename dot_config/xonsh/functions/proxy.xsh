import sys

from xonsh.built_ins import XSH


def _proxy(args, stdin=None):
    if len(args) > 2:
        print("usage: proxy [host] [port]", file=sys.stderr)
        return 2

    host = args[0] if len(args) >= 1 else XSH.env.get("PROXY_HOST", "127.0.0.1")
    port = args[1] if len(args) >= 2 else XSH.env.get("PROXY_PORT", "3067")
    url = f"http://{host}:{port}"
    for name in ("http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY"):
        XSH.env[name] = url
    print(f"proxy on ({host}:{port})")


def _socks5(args, stdin=None):
    if len(args) > 2:
        print("usage: socks5 [host] [port]", file=sys.stderr)
        return 2

    host = args[0] if len(args) >= 1 else XSH.env.get("PROXY_HOST", "127.0.0.1")
    port = args[1] if len(args) >= 2 else XSH.env.get("PROXY_PORT", "3067")
    url = f"socks5://{host}:{port}"
    for name in ("all_proxy", "ALL_PROXY"):
        XSH.env[name] = url
    print(f"socks5 on ({host}:{port})")


def _unproxy(args, stdin=None):
    if args:
        print("usage: unproxy", file=sys.stderr)
        return 2

    for name in ("http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY", "all_proxy", "ALL_PROXY"):
        XSH.env.pop(name, None)
    print("proxy off")


def _proxyinfo(args, stdin=None):
    if args:
        print("usage: proxyinfo", file=sys.stderr)
        return 2

    print(f"http : {XSH.env.get('http_proxy', 'unset')}")
    print(f"https: {XSH.env.get('https_proxy', 'unset')}")
    print(f"socks: {XSH.env.get('all_proxy', 'unset')}")


aliases["proxy"] = _proxy
aliases["socks5"] = _socks5
aliases["unproxy"] = _unproxy
aliases["proxyinfo"] = _proxyinfo
