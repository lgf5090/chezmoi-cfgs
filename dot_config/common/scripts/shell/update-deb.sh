#!/usr/bin/env bash

set -euo pipefail

# ======================== 默认配置 ========================
DEFAULT_REPO="esengine/DeepSeek-Reasonix"
DEFAULT_TAG_PREFIX="desktop-v"
# ==========================================================

TEMP_DEB=$(mktemp /tmp/update_deb_XXXXXX.deb)
trap 'rm -f "$TEMP_DEB"' EXIT
rm -f "$TEMP_DEB"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
declare -A ARCH_ALIASES
ARCH_ALIASES[amd64]="x86_64 x64"
ARCH_ALIASES[arm64]="aarch64 arm64v8"
ARCH_ALIASES[armhf]="armv7l armhf"
ARCH_ALIASES[i386]="i686 x86"

REPO="$DEFAULT_REPO"
TARGET_VERSION=""
FORCE=0
MANUAL_PACKAGE=""
TAG_PREFIX="$DEFAULT_TAG_PREFIX"

# ======================== 函数 ========================

usage() {
    cat <<EOF
用法: $0 [选项]

选项:
  -r, --repo REPO         目标 GitHub 仓库 (格式: owner/repo)
                          (默认: ${DEFAULT_REPO})
  -v, --version VERSION   指定版本 (如 1.2.3)，默认安装最新版
  -f, --force             强制安装，即使已安装相同版本
  -p, --package NAME      手动指定已安装的包名
  --tag-prefix PREFIX     release tag 前缀
                          (默认: "${DEFAULT_TAG_PREFIX}" 针对默认仓库)
  -h, --help              显示帮助

说明:
  脚本智能匹配系统架构（含常见别名），自动识别已安装包名（支持驼峰拆分、
  连字符变体），下载对应的 .deb 并安装。
  下载优先级: axel → aria2c → wget → curl。

示例:
  $0
  $0 -r edison7009/EchoBird --tag-prefix "v"
  $0 -r farion1231/cc-switch -v 3.16.3 --tag-prefix ""
EOF
    exit 0
}

die() {
    echo -e "${RED}错误: $*${NC}" >&2
    exit 1
}

# ------------------------------------------------------------
# 智能检测包名（支持驼峰、连字符、下划线变体）
# ------------------------------------------------------------
detect_package_name() {
    if [[ -n "$MANUAL_PACKAGE" ]]; then
        echo "$MANUAL_PACKAGE"
        return
    fi

    local repo_slug
    repo_slug=$(echo "$REPO" | awk -F'/' '{print $2}')

    # 1. 精确包含（忽略大小写）
    local exact
    exact=$(dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -i -F "$repo_slug" | head -1)
    if [[ -n "$exact" ]]; then
        echo "$exact"
        return
    fi

    # 2. 拆分单词：先按连字符/下划线拆分，再对每部分按大小写边界拆分
    local words=()
    # 将 repo_slug 中的连字符、下划线替换为空格，然后按大小写边界插入空格
    local normalized
    normalized=$(echo "$repo_slug" | sed 's/[-_]/ /g' | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g' | tr '[:upper:]' '[:lower:]')
    for w in $normalized; do
        [[ -n "$w" ]] && words+=("$w")
    done

    # 从已安装包中寻找同时包含所有单词的包（不区分大小写，任意顺序）
    local candidate=""
    while IFS= read -r pkg; do
        local pkg_lower=$(echo "$pkg" | tr '[:upper:]' '[:lower:]')
        local all_found=1
        for w in "${words[@]}"; do
            if [[ "$pkg_lower" != *"$w"* ]]; then
                all_found=0
                break
            fi
        done
        if [[ $all_found -eq 1 ]]; then
            candidate="$pkg"
            break
        fi
    done < <(dpkg-query -W -f='${Package}\n' 2>/dev/null)

    if [[ -n "$candidate" ]]; then
        echo "$candidate"
        return
    fi

    # 3. 回退：已知映射或小写 slug
    local lower_slug=$(echo "$repo_slug" | tr '[:upper:]' '[:lower:]')
    case "$lower_slug" in
        deepseek-reasonix) echo "reasonix-desktop" ;;
        *)                 echo "$lower_slug" ;;
    esac
}

get_installed_version() {
    local pkg="$1"
    local ver
    ver=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null) || true
    echo "${ver:-}"
}

get_latest_tag() {
    local api_url="https://api.github.com/repos/${REPO}/releases/latest"
    local tmpfile=$(mktemp /tmp/update_deb_api_XXXXXX)
    local http_code tag

    if command -v curl &>/dev/null; then
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            http_code=$(curl -sL -w "%{http_code}" -o "$tmpfile" -H "Authorization: token ${GITHUB_TOKEN}" "$api_url")
        else
            http_code=$(curl -sL -w "%{http_code}" -o "$tmpfile" "$api_url")
        fi
    elif command -v wget &>/dev/null; then
        local wget_out
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            wget_out=$(wget --header="Authorization: token ${GITHUB_TOKEN}" -S -O "$tmpfile" "$api_url" 2>&1)
        else
            wget_out=$(wget -S -O "$tmpfile" "$api_url" 2>&1)
        fi
        http_code=$(echo "$wget_out" | grep -oP 'HTTP/\d\.\d \K\d{3}' | tail -1)
    else
        die "需要 curl 或 wget"
    fi

    [[ "$http_code" != "200" ]] && die "GitHub API 返回 HTTP $http_code"
    tag=$(sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' "$tmpfile")
    rm -f "$tmpfile"
    [[ -z "$tag" ]] && die "无法解析 tag_name"
    echo "$tag"
}

get_possible_tags() {
    local version="$1"
    if [[ -n "$TAG_PREFIX" ]]; then
        echo "${TAG_PREFIX}${version}"
    else
        echo "v${version}"
        echo "${version}"
        echo "release-${version}"
        echo "rel-${version}"
    fi
}

tag_exists() {
    local tag="$1"
    local api_url="https://api.github.com/repos/${REPO}/releases/tags/${tag}"
    local http_code

    if command -v curl &>/dev/null; then
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            http_code=$(curl -sL -o /dev/null -w "%{http_code}" -H "Authorization: token ${GITHUB_TOKEN}" "$api_url")
        else
            http_code=$(curl -sL -o /dev/null -w "%{http_code}" "$api_url")
        fi
    elif command -v wget &>/dev/null; then
        local wget_out
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            wget_out=$(wget --header="Authorization: token ${GITHUB_TOKEN}" --spider -S "$api_url" 2>&1)
        else
            wget_out=$(wget --spider -S "$api_url" 2>&1)
        fi
        http_code=$(echo "$wget_out" | grep -oP 'HTTP/\d\.\d \K\d{3}' | head -1)
    else
        die "需要 curl 或 wget"
    fi
    [[ "$http_code" == "200" ]]
}

get_asset_url() {
    local tag="$1"
    local api_url="https://api.github.com/repos/${REPO}/releases/tags/${tag}"
    local tmpfile=$(mktemp /tmp/update_deb_asset_XXXXXX)
    local http_code

    if command -v curl &>/dev/null; then
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            http_code=$(curl -sL -w "%{http_code}" -o "$tmpfile" -H "Authorization: token ${GITHUB_TOKEN}" "$api_url")
        else
            http_code=$(curl -sL -w "%{http_code}" -o "$tmpfile" "$api_url")
        fi
    elif command -v wget &>/dev/null; then
        local wget_out
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            wget_out=$(wget --header="Authorization: token ${GITHUB_TOKEN}" -S -O "$tmpfile" "$api_url" 2>&1)
        else
            wget_out=$(wget -S -O "$tmpfile" "$api_url" 2>&1)
        fi
        http_code=$(echo "$wget_out" | grep -oP 'HTTP/\d\.\d \K\d{3}' | tail -1)
    else
        die "需要 curl 或 wget"
    fi

    [[ "$http_code" != "200" ]] && die "GitHub API 返回 HTTP $http_code"

    local -a arch_ids=("$ARCH")
    if [[ -n "${ARCH_ALIASES[$ARCH]:-}" ]]; then
        for alias in ${ARCH_ALIASES[$ARCH]}; do
            arch_ids+=("$alias")
        done
    fi
    local arch_pattern
    arch_pattern=$(IFS='|'; echo "${arch_ids[*]}")

    local matched_url=""
    local deb_urls=()
    while IFS= read -r line; do
        local url
        url=$(echo "$line" | sed -n 's/.*"browser_download_url": *"\([^"]*\)".*/\1/p')
        [[ -z "$url" ]] && continue
        if [[ "$url" =~ \.deb$ ]]; then
            deb_urls+=("$url")
            local filename=$(basename "$url")
            if echo "$filename" | grep -iqE "($arch_pattern)"; then
                matched_url="$url"
                break
            fi
        fi
    done < <(grep -i '"browser_download_url":' "$tmpfile")
    rm -f "$tmpfile"

    if [[ -z "$matched_url" ]]; then
        echo -e "${YELLOW}未找到匹配架构的 .deb 包，架构: $ARCH，模式: ($arch_pattern)${NC}"
        echo -e "${YELLOW}Release 中所有 .deb 资产:${NC}"
        for deb_url in "${deb_urls[@]}"; do
            echo "  $(basename "$deb_url")"
        done
        die "自动匹配失败"
    fi
    echo "$matched_url"
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
        die "未找到可用下载工具"
    fi
}

version_lt() {
    local a="$1" b="$2"
    if command -v dpkg &>/dev/null; then
        ! dpkg --compare-versions "$a" ge "$b"
    else
        local first=$(printf '%s\n%s\n' "$a" "$b" | sort -V | head -1)
        [[ "$first" != "$b" ]]
    fi
}

# ======================== 主程序 ========================
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--repo)      REPO="$2"; shift 2 ;;
            -v|--version)   TARGET_VERSION="$2"; shift 2 ;;
            -f|--force)     FORCE=1; shift ;;
            -p|--package)   MANUAL_PACKAGE="$2"; shift 2 ;;
            --tag-prefix)   TAG_PREFIX="$2"; shift 2 ;;
            -h|--help)      usage ;;
            *)              die "未知参数: $1" ;;
        esac
    done

    if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
        die "仓库格式错误"
    fi

    echo -e "仓库: ${REPO}"
    echo -e "系统架构: ${ARCH}"
    [[ -n "$TAG_PREFIX" ]] && echo -e "Tag 前缀: \"${TAG_PREFIX}\"" || echo -e "Tag 前缀: (无)"

    local install_version=""
    local tag=""

    if [[ -n "$TARGET_VERSION" ]]; then
        local found_tag=""
        for cand_tag in $(get_possible_tags "$TARGET_VERSION"); do
            echo -e "尝试 tag: ${cand_tag} ..."
            if tag_exists "$cand_tag"; then
                found_tag="$cand_tag"
                break
            fi
        done
        [[ -z "$found_tag" ]] && die "未找到版本 ${TARGET_VERSION}"
        tag="$found_tag"
        install_version="$TARGET_VERSION"
    else
        echo -e "正在查询最新 release..."
        tag=$(get_latest_tag)
        if [[ -n "$TAG_PREFIX" && "$tag" =~ ^${TAG_PREFIX}(.+)$ ]]; then
            install_version="${BASH_REMATCH[1]}"
        else
            install_version="${tag#v}"
        fi
        [[ -z "$install_version" ]] && die "无法提取版本号"
    fi

    echo -e "目标版本: ${install_version} (tag: ${tag})"

    local pkg_name=$(detect_package_name)
    echo -e "目标包名: ${pkg_name}"

    local current_version=$(get_installed_version "$pkg_name")
    if [[ -n "$current_version" ]]; then
        echo -e "${GREEN}当前已安装 ${pkg_name} 版本: ${current_version}${NC}"
    else
        echo -e "${YELLOW}未安装 ${pkg_name}${NC}"
    fi

    if [[ -n "$current_version" && "$FORCE" -eq 0 ]]; then
        if [[ "$current_version" == "$install_version" ]]; then
            echo -e "${GREEN}已是最新版本。重装请加 -f${NC}"
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

    echo -e "正在查找 release ${tag} 中匹配架构的 .deb 包..."
    local download_url
    download_url=$(get_asset_url "$tag")
    echo -e "下载地址: ${download_url}"

    download_file "$download_url" "$TEMP_DEB"

    echo -e "${YELLOW}正在安装 ${pkg_name} ${install_version}...${NC}"
    if [[ $EUID -ne 0 ]]; then
        sudo dpkg -i "$TEMP_DEB" || die "dpkg 安装失败"
    else
        dpkg -i "$TEMP_DEB" || die "dpkg 安装失败"
    fi

    echo -e "${GREEN}安装完成！${NC}"
}

main "$@"