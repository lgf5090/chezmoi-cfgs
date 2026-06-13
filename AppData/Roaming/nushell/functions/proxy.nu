def --env proxy [...args: string] {
    let n = ($args | length)
    if $n > 2 {
        print -e "usage: proxy [[host] port]"
        return
    }

    let default_host = ($env.PROXY_HOST? | default "127.0.0.1")
    let default_port = ($env.PROXY_PORT? | default "3067")
    let host = if $n == 2 { $args.0 } else { $default_host }
    let port = if $n == 2 { $args.1 } else if $n == 1 { $args.0 } else { $default_port }
    let url = $"http://($host):($port)"

    $env.http_proxy = $url
    $env.https_proxy = $url
    $env.HTTP_PROXY = $url
    $env.HTTPS_PROXY = $url

    print $"proxy on \(($host):($port)\)"
}

def --env socks5 [...args: string] {
    let n = ($args | length)
    if $n > 2 {
        print -e "usage: socks5 [[host] port]"
        return
    }

    let default_host = ($env.PROXY_HOST? | default "127.0.0.1")
    let default_port = ($env.PROXY_PORT? | default "3067")
    let host = if $n == 2 { $args.0 } else { $default_host }
    let port = if $n == 2 { $args.1 } else if $n == 1 { $args.0 } else { $default_port }
    let url = $"socks5://($host):($port)"

    $env.all_proxy = $url
    $env.ALL_PROXY = $url

    print $"socks5 on \(($host):($port)\)"
}

def --env unproxy [] {
    hide-env --ignore-errors http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
    print "proxy off"
}

def proxyinfo [] {
    print $"http : ($env.http_proxy? | default 'unset')"
    print $"https: ($env.https_proxy? | default 'unset')"
    print $"socks: ($env.all_proxy? | default 'unset')"
}
