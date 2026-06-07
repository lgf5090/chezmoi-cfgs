function proxy {
    param(
        [Parameter(Position=0)][string]$HostName,
        [Parameter(Position=1)][string]$Port
    )

    if ([string]::IsNullOrWhiteSpace($HostName)) {
        $HostName = if ($env:PROXY_HOST) { $env:PROXY_HOST } else { '127.0.0.1' }
    }
    if ([string]::IsNullOrWhiteSpace($Port)) {
        $Port = if ($env:PROXY_PORT) { $env:PROXY_PORT } else { '3067' }
    }

    $url = "http://${HostName}:${Port}"
    $env:http_proxy = $url
    $env:https_proxy = $url
    $env:HTTP_PROXY = $url
    $env:HTTPS_PROXY = $url
    "proxy on (${HostName}:${Port})"
}

function socks5 {
    param(
        [Parameter(Position=0)][string]$HostName,
        [Parameter(Position=1)][string]$Port
    )

    if ([string]::IsNullOrWhiteSpace($HostName)) {
        $HostName = if ($env:PROXY_HOST) { $env:PROXY_HOST } else { '127.0.0.1' }
    }
    if ([string]::IsNullOrWhiteSpace($Port)) {
        $Port = if ($env:PROXY_PORT) { $env:PROXY_PORT } else { '3067' }
    }

    $url = "socks5://${HostName}:${Port}"
    $env:all_proxy = $url
    $env:ALL_PROXY = $url
    "socks5 on (${HostName}:${Port})"
}

function unproxy {
    Remove-Item Env:http_proxy,Env:https_proxy,Env:HTTP_PROXY,Env:HTTPS_PROXY,Env:all_proxy,Env:ALL_PROXY -ErrorAction SilentlyContinue
    'proxy off'
}

function proxyinfo {
    "http : $(if ($env:http_proxy) { $env:http_proxy } else { 'unset' })"
    "https: $(if ($env:https_proxy) { $env:https_proxy } else { 'unset' })"
    "socks: $(if ($env:all_proxy) { $env:all_proxy } else { 'unset' })"
}
