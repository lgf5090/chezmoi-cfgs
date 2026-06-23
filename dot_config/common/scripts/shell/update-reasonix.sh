#!/usr/bin/env bash

set -euo pipefail

# ======================== 配置 ========================
REPO="esengine/DeepSeek-Reasonix"
PACKAGE_NAME="reasonix"
BASE_URL="https://github.com/${REPO}/releases/download"
TAG_PREFIX="desktop-v"
DEB_FILENAME="Reasonix-linux-amd64.deb"

# 安全创建临时文件名（立即删除，由下载工具创建）
TEMP_DEB=$(mktemp /tmp/reasonix_XXXXXX.deb)
trap 'rm -f "$TEMP_DEB"' EXIT
rm -f "$TEMP_DEB"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

FORCE=0

# ======================== 函数 ========================

usage() {
    cat <<EOF
用法: $0 [选项] [版本号]

选项:
  -f, --force   强制安装（即使已安装相同版本）
  -h, --help    显示帮助
  版本号        指定版本（如 1.11.2），默认安装最新版

环境变量:
  GITHUB_TOKEN  GitHub 令牌（可选）

示例:
  $0              # 安装最新版
  $0 1.11.2       # 安装指定版本
  $0 -f           # 强制重装最新版
EOF
    exit 0
}

die() {
    echo -e "${RED}错误: $*${NC}" >&2
    exit 1
}

get_installed_version() {
    local ver
    ver=$(dpkg-query -W -f='${Version}' "$PACKAGE_NAME" 2>/dev/null) || true
    echo "${ver:-}"
}

get_latest_tag() {
    local api_url="https://api.github.com/repos/${REPO}/releases/latest"
    local tag=""
    local tmpfile
    tmpfile=$(mktemp /tmp/reasonix_api_XXXXXX)

    if command -v curl &>/dev/null; then
        local http_code
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            http_code=$(curl -sL -w "%{http_code}" -o "$tmpfile" -H "Authorization: token ${GITHUB_TOKEN}" "$api_url")
        else
            http_code=$(curl -sL -w "%{http_code}" -o "$tmpfile" "$api_url")
        fi
        [[ "$http_code" != "200" ]] && die "GitHub API 返回 HTTP $http_code"
        tag=$(sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' "$tmpfile")
    elif command -v wget &>/dev/null; then
        local wget_out
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            wget_out=$(wget --header="Authorization: token ${GITHUB_TOKEN}" -S -O "$tmpfile" "$api_url" 2>&1)
        else
            wget_out=$(wget -S -O "$tmpfile" "$api_url" 2>&1)
        fi
        local http_code
        http_code=$(echo "$wget_out" | grep -oP 'HTTP/\d\.\d \K\d{3}' | tail -1)
        [[ "$http_code" != "200" ]] && die "GitHub API 返回 HTTP $http_code"
        tag=$(sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' "$tmpfile")
    else
        die "需要 curl 或 wget"
    fi

    rm -f "$tmpfile"
    [[ -z "$tag" ]] && die "无法解析 tag_name"
    echo "$tag"
}

extract_version_from_tag() {
    local tag="$1"
    if [[ "$tag" =~ ^${TAG_PREFIX}(.+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "$tag"
    fi
}

version_lt() {
    local a="$1" b="$2"
    if command -v dpkg &>/dev/null; then
        ! dpkg --compare-versions "$a" ge "$b"
    else
        local first
        first=$(printf '%s\n%s\n' "$a" "$b" | sort -V | head -1)
        [[ "$first" != "$b" ]]
    fi
}

download_file() {
    local url="$1" output="$2"

    if command -v axel &>/dev/null; then
        echo -e "${YELLOW}使用 axel 下载...${NC}"
        axel -n 4 -o "$output" "$url" || die "axel 下载失败"
    elif command -v aria2c &>/dev/null; then
        echo -e "${YELLOW}使用 aria2c 下载...${NC}"
        aria2c -x 4 -o "$output" "$url" || die "aria2c 下载失败"
    elif command -v wget &>/dev/null; then
        echo -e "${YELLOW}使用 wget 下载...${NC}"
        wget -O "$output" "$url" || die "wget 下载失败"
    elif command -v curl &>/dev/null; then
        echo -e "${YELLOW}使用 curl 下载...${NC}"
        curl -L -o "$output" "$url" || die "curl 下载失败"
    else
        die "未找到可用下载工具（axel/aria2c/wget/curl）"
    fi
}

# ======================== 主程序 ========================
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force) FORCE=1; shift ;;
            -h|--help)  usage ;;
            *)          break ;;
        esac
    done

    local target_version=""
    if [[ $# -eq 1 ]]; then
        target_version="$1"
    elif [[ $# -gt 1 ]]; then
        die "参数过多，请用 -h 查看帮助"
    fi

    local current_version=$(get_installed_version)
    if [[ -n "$current_version" ]]; then
        echo -e "${GREEN}当前已安装版本: ${current_version}${NC}"
    else
        echo -e "${YELLOW}未安装 ${PACKAGE_NAME}${NC}"
    fi

    local install_version=""
    local tag=""

    if [[ -n "$target_version" ]]; then
        install_version="$target_version"
        tag="${TAG_PREFIX}${install_version}"
        echo -e "目标版本: ${install_version}"
    else
        echo -e "正在查询最新 release..."
        tag=$(get_latest_tag)
        install_version=$(extract_version_from_tag "$tag")
        [[ -z "$install_version" ]] && die "无法从 tag '$tag' 提取版本号"
        echo -e "最新版本: ${install_version} (tag: ${tag})"
    fi

    if [[ -n "$current_version" && "$FORCE" -eq 0 ]]; then
        if [[ "$current_version" == "$install_version" ]]; then
            echo -e "${GREEN}当前已是最新版本，无需操作。如需重装请加 -f${NC}"
            exit 0
        fi

        if version_lt "$current_version" "$install_version"; then
            echo -e "发现新版本: ${current_version} → ${install_version}"
        else
            echo -e "当前版本 (${current_version}) 高于目标 (${install_version})，确认降级？(y/N)"
            read -r answer
            if [[ ! "$answer" =~ ^[Yy]$ ]]; then
                echo "已取消。"
                exit 0
            fi
        fi
    fi

    local download_url="${BASE_URL}/${tag}/${DEB_FILENAME}"
    echo -e "下载地址: ${download_url}"

    download_file "$download_url" "$TEMP_DEB"

    echo -e "${YELLOW}正在安装 ${PACKAGE_NAME} ${install_version}...${NC}"
    if [[ $EUID -ne 0 ]]; then
        sudo dpkg -i "$TEMP_DEB" || die "dpkg 安装失败"
    else
        dpkg -i "$TEMP_DEB" || die "dpkg 安装失败"
    fi

    echo -e "${GREEN}安装完成！${NC}"
}

main "$@"