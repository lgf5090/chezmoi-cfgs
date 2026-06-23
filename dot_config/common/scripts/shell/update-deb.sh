#!/usr/bin/env bash

set -euo pipefail

# ======================== 默认配置 ========================
DEFAULT_REPO="esengine/DeepSeek-Reasonix"
DEFAULT_TAG_PREFIX="desktop-v"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/update-deb"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/update-deb/config"
# ==========================================================

# 颜色与样式定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志输出函数 (使用 printf 避免 echo 的 -e/-n 兼容问题)
log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[OK]${NC} %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
die()         { log_error "$*"; exit 1; }

# 依赖检查
require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        die "缺少必要依赖: $cmd，请先安装。"
    fi
}

# 初始化环境与依赖
init_dependencies() {
    require_cmd dpkg
    
    # HTTP 客户端
    if command -v curl &>/dev/null; then
        HTTP_CLIENT="curl"
    elif command -v wget &>/dev/null; then
        HTTP_CLIENT="wget"
    else
        die "需要 curl 或 wget"
    fi

    # JSON 解析器
    if command -v jq &>/dev/null; then
        JSON_PARSER="jq"
    elif command -v python3 &>/dev/null; then
        JSON_PARSER="python3"
    else
        die "需要 jq 或 python3 来解析 GitHub API 响应"
    fi
}

# 规范化系统架构 (统一为 dpkg 标准名称)
normalize_arch() {
    local arch="$1"
    case "$arch" in
        x86_64|x64) echo "amd64" ;;
        aarch64|arm64v8) echo "arm64" ;;
        armv7l) echo "armhf" ;;
        i686|x86) echo "i386" ;;
        *) echo "$arch" ;;
    esac
}

# HTTP GET 封装 (支持超时、重试、Token)
http_get() {
    local url="$1"
    local output="$2"
    local timeout="${3:-15}"
    local max_retries="${4:-3}"
    
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    local headers=()
    [[ -n "$token" ]] && headers+=("-H" "Authorization: token $token")
    
    local attempt=1
    while [[ $attempt -le $max_retries ]]; do
        if [[ "$HTTP_CLIENT" == "curl" ]]; then
            local curl_opts=(-sL --max-time "$timeout" --retry 2)
            if [[ ${#headers[@]} -gt 0 ]]; then curl_opts+=("${headers[@]}"); fi
            
            if [[ -n "$output" ]]; then
                local http_code
                http_code=$(curl "${curl_opts[@]}" -o "$output" -w "%{http_code}" "$url" 2>/dev/null) || http_code="000"
                if [[ "$http_code" == "200" ]]; then return 0; fi
                log_warn "curl 请求失败 (HTTP $http_code)，尝试 $attempt/$max_retries..."
            else
                if curl "${curl_opts[@]}" "$url" >/dev/null 2>&1; then return 0; fi
                log_warn "curl 请求失败，尝试 $attempt/$max_retries..."
            fi
        else # wget
            local wget_opts=(-q --timeout="$timeout" --tries=2)
            [[ -n "$token" ]] && wget_opts+=(--header="Authorization: token $token")
            
            if [[ -n "$output" ]]; then
                if wget "${wget_opts[@]}" -O "$output" "$url" 2>/dev/null; then return 0; fi
                log_warn "wget 请求失败，尝试 $attempt/$max_retries..."
            else
                if wget "${wget_opts[@]}" -O - "$url" >/dev/null 2>&1; then return 0; fi
                log_warn "wget 请求失败，尝试 $attempt/$max_retries..."
            fi
        fi
        ((attempt++))
        sleep 1
    done
    return 1
}

# 加载本地配置文件
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
    fi
}

# 获取可能的 Tag 列表
get_possible_tags() {
    local version="$1"
    local tags=()
    if [[ -n "$TAG_PREFIX" ]]; then
        tags+=("${TAG_PREFIX}${version}")
    fi
    tags+=("v${version}" "${version}" "release-${version}" "rel-${version}")
    printf "%s\n" "${tags[@]}" | awk '!seen[$0]++'
}

# 获取 Release 信息 (返回 tmpfile 路径)
get_release_info() {
    local tag="$1"
    local api_url
    if [[ -z "$tag" ]]; then
        api_url="https://api.github.com/repos/${REPO}/releases/latest"
    else
        api_url="https://api.github.com/repos/${REPO}/releases/tags/${tag}"
    fi
    
    local tmpfile
    tmpfile=$(mktemp)
    
    if ! http_get "$api_url" "$tmpfile"; then
        rm -f "$tmpfile"
        return 1
    fi
    
    # 检查是否返回了 Not Found 错误
    local msg
    if [[ "$JSON_PARSER" == "jq" ]]; then
        msg=$(jq -r '.message // empty' "$tmpfile")
    else
        msg=$(python3 -c "import sys, json
try: print(json.load(open('$tmpfile')).get('message', ''))
except: pass" 2>/dev/null || true)
    fi
    
    if [[ "$msg" == "Not Found" ]]; then
        rm -f "$tmpfile"
        return 1
    fi
    
    echo "$tmpfile"
    return 0
}

# 智能检测包名
detect_package_name() {
    if [[ -n "${MANUAL_PACKAGE:-}" ]]; then
        echo "$MANUAL_PACKAGE"
        return
    fi

    local repo_slug
    repo_slug=$(echo "$REPO" | awk -F'/' '{print $2}')

    # 1. 精确包含（忽略大小写）
    local exact
    exact=$(dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -i -F "$repo_slug" | head -n 1)
    if [[ -n "$exact" ]]; then
        echo "$exact"
        return
    fi

    # 2. 拆分单词匹配
    local words=()
    local normalized
    normalized=$(echo "$repo_slug" | sed 's/[-_]/ /g' | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g' | tr '[:upper:]' '[:lower:]')
    for w in $normalized; do
        [[ -n "$w" ]] && words+=("$w")
    done

    local candidate=""
    while IFS= read -r pkg; do
        local pkg_lower
        pkg_lower=$(echo "$pkg" | tr '[:upper:]' '[:lower:]')
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

    # 3. 回退映射
    local lower_slug
    lower_slug=$(echo "$repo_slug" | tr '[:upper:]' '[:lower:]')
    case "$lower_slug" in
        deepseek-reasonix) echo "reasonix-desktop" ;;
        *)                 echo "$lower_slug" ;;
    esac
}

get_installed_version() {
    local pkg="$1"
    dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true
}

# 获取架构匹配的正则模式
get_arch_patterns() {
    local arch="$1"
    local patterns=("$arch")
    case "$arch" in
        amd64) patterns+=("x86_64" "x64" "amd64") ;;
        arm64) patterns+=("aarch64" "arm64v8" "arm64") ;;
        armhf) patterns+=("armv7l" "armhf" "armv7") ;;
        i386)  patterns+=("i686" "x86" "i386") ;;
    esac
    printf "%s\n" "${patterns[@]}" | sort -u | paste -sd '|' -
}

# 提取 .deb 下载链接
get_asset_url() {
    local tag="$1"
    local tmpfile
    if ! tmpfile=$(get_release_info "$tag"); then
        die "无法获取 release 信息: $tag"
    fi
    
    local arch_patterns
    arch_patterns=$(get_arch_patterns "$ARCH")
    
    local matched_url=""
    local all_deb_urls=()
    
    if [[ "$JSON_PARSER" == "jq" ]]; then
        matched_url=$(jq -r --arg pattern "$arch_patterns" '
            .assets[] | 
            select(.name | endswith(".deb")) | 
            select(.name | test($pattern; "i")) | 
            .browser_download_url' "$tmpfile" | head -n 1)
            
        if [[ -z "$matched_url" ]]; then
            while IFS= read -r line; do
                all_deb_urls+=("$line")
            done < <(jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url' "$tmpfile")
        fi
    else
        # Python Fallback
        local py_script="
import json, re, sys
try:
    data = json.load(open('$tmpfile'))
except:
    sys.exit(1)
pattern = re.compile(r'($arch_patterns)', re.IGNORECASE)
fallback = []
match_found = ''
for asset in data.get('assets', []):
    name = asset.get('name', '')
    url = asset.get('browser_download_url', '')
    if name.endswith('.deb'):
        if not match_found and pattern.search(name):
            match_found = url
        else:
            fallback.append(url)
print('MATCH:' + match_found)
for u in fallback: print('FALLBACK:' + u)
"
        local py_out
        py_out=$(python3 -c "$py_script" 2>/dev/null || true)
        matched_url=$(echo "$py_out" | grep "^MATCH:" | cut -d: -f2- || true)
        
        while IFS= read -r line; do
            local url="${line#FALLBACK:}"
            [[ -n "$url" ]] && all_deb_urls+=("$url")
        done < <(echo "$py_out" | grep "^FALLBACK:" || true)
    fi

    rm -f "$tmpfile"
    
    if [[ -n "$matched_url" ]]; then
        echo "$matched_url"
        return 0
    fi
    
    log_warn "未找到匹配架构 ($ARCH) 的 .deb 包"
    if [[ ${#all_deb_urls[@]} -gt 0 ]]; then
        log_warn "Release 中所有的 .deb 资产:"
        for u in "${all_deb_urls[@]}"; do
            printf "  - %s\n" "$(basename "$u")"
        done
    else
        log_warn "该 Release 中没有任何 .deb 资产"
    fi
    die "自动匹配架构失败，请检查 Release 资产或手动指定。"
}

# 下载文件 (带缓存和进度条)
download_file() {
    local url="$1"
    local output="$2"
    
    local filename
    filename=$(basename "$url")
    local cache_file="$CACHE_DIR/$filename"
    
    mkdir -p "$CACHE_DIR"
    
    if [[ -f "$cache_file" ]]; then
        log_info "发现本地缓存: $cache_file"
        cp "$cache_file" "$output"
        return 0
    fi

    log_info "正在下载: $filename"
    
    local downloaded=0
    if command -v aria2c &>/dev/null; then
        log_info "使用 aria2c 多线程下载..."
        aria2c -x 4 -s 4 -d "$CACHE_DIR" -o "$filename" "$url" && downloaded=1
    elif command -v axel &>/dev/null; then
        log_info "使用 axel 多线程下载..."
        axel -n 4 -o "$cache_file" "$url" && downloaded=1
    elif command -v wget &>/dev/null; then
        log_info "使用 wget 下载..."
        wget --show-progress -O "$cache_file" "$url" && downloaded=1
    elif command -v curl &>/dev/null; then
        log_info "使用 curl 下载..."
        curl -# -L -o "$cache_file" "$url" && downloaded=1
    else
        die "未找到可用下载工具 (aria2c, axel, wget, curl)"
    fi
    
    if [[ $downloaded -eq 1 && -f "$cache_file" ]]; then
        cp "$cache_file" "$output"
        return 0
    else
        die "下载失败: $url"
    fi
}

# 版本比较
version_compare() {
    local a="$1" b="$2"
    if command -v dpkg &>/dev/null; then
        if dpkg --compare-versions "$a" gt "$b"; then echo 1;
        elif dpkg --compare-versions "$a" lt "$b"; then echo -1;
        else echo 0; fi
    else
        local first
        first=$(printf '%s\n%s\n' "$a" "$b" | sort -V | head -n 1)
        if [[ "$first" == "$a" && "$a" != "$b" ]]; then echo -1;
        elif [[ "$first" == "$b" && "$a" != "$b" ]]; then echo 1;
        else echo 0; fi
    fi
}

# 安装与依赖修复
install_deb() {
    local deb_file="$1"
    local pkg_name="$2"
    
    log_info "正在安装 $pkg_name..."
    
    local cmd_prefix=""
    if [[ $EUID -ne 0 ]]; then
        if command -v sudo &>/dev/null; then
            cmd_prefix="sudo"
        else
            die "需要 root 权限进行安装，且未找到 sudo"
        fi
    fi
    
    if ! $cmd_prefix dpkg -i "$deb_file"; then
        log_warn "dpkg 安装过程中出现依赖错误，正在尝试自动修复..."
        if command -v apt-get &>/dev/null; then
            $cmd_prefix apt-get update -qq >/dev/null 2>&1 || true
            if ! $cmd_prefix apt-get install -f -y; then
                die "自动修复依赖失败，请手动执行: $cmd_prefix apt-get install -f"
            fi
            $cmd_prefix dpkg --configure -a >/dev/null 2>&1 || true
            log_success "依赖修复完成！"
        else
            die "安装失败且未找到 apt-get 来修复依赖"
        fi
    fi
    
    log_success "安装成功！"
}

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
  -c, --clean-cache       清理本地下载缓存
  -h, --help              显示帮助

说明:
  脚本智能匹配系统架构，自动识别已安装包名，下载对应的 .deb 并安装。
  遇到依赖缺失时会自动调用 apt-get 修复。
  支持配置文件: ${CONFIG_FILE}

示例:
  $0
  $0 -r edison7009/EchoBird --tag-prefix "v"
  $0 -c  # 仅清理缓存
EOF
    exit 0
}

# ======================== 主程序 ========================
main() {
    # 参数解析
    REPO="$DEFAULT_REPO"
    TARGET_VERSION=""
    FORCE=0
    MANUAL_PACKAGE=""
    TAG_PREFIX="$DEFAULT_TAG_PREFIX"
    CLEAN_CACHE=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--repo)      [[ -z "${2:-}" ]] && die "参数 $1 缺少值"; REPO="$2"; shift 2 ;;
            -v|--version)   [[ -z "${2:-}" ]] && die "参数 $1 缺少值"; TARGET_VERSION="$2"; shift 2 ;;
            -f|--force)     FORCE=1; shift ;;
            -p|--package)   [[ -z "${2:-}" ]] && die "参数 $1 缺少值"; MANUAL_PACKAGE="$2"; shift 2 ;;
            --tag-prefix)   [[ -z "${2:-}" ]] && die "参数 $1 缺少值"; TAG_PREFIX="$2"; shift 2 ;;
            -c|--clean-cache) CLEAN_CACHE=1; shift ;;
            -h|--help)      usage ;;
            *)              die "未知参数: $1" ;;
        esac
    done

    init_dependencies
    load_config

    if [[ "${CLEAN_CACHE:-0}" -eq 1 ]]; then
        log_info "正在清理缓存目录: $CACHE_DIR"
        rm -rf "$CACHE_DIR"
        log_success "缓存清理完毕"
        [[ $# -eq 0 && -z "${TARGET_VERSION:-}" ]] && exit 0
    fi

    if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
        die "仓库格式错误: $REPO"
    fi

    # 规范化架构
    ARCH=$(normalize_arch "$(dpkg --print-architecture 2>/dev/null || uname -m)")

    log_info "仓库: ${REPO}"
    log_info "系统架构: ${ARCH}"
    [[ -n "$TAG_PREFIX" ]] && log_info "Tag 前缀: \"${TAG_PREFIX}\"" || log_info "Tag 前缀: (无)"

    local install_version=""
    local tag=""
    local tmpfile=""

    if [[ -n "$TARGET_VERSION" ]]; then
        # 清理用户输入的 version 前缀
        local clean_version="$TARGET_VERSION"
        for prefix in "v" "release-" "rel-" "version-"; do
            if [[ "$clean_version" == "$prefix"* ]]; then
                clean_version="${clean_version#"$prefix"}"
                break
            fi
        done
        TARGET_VERSION="$clean_version"

        local found_tag=""
        for cand_tag in $(get_possible_tags "$TARGET_VERSION"); do
            log_info "尝试 tag: ${cand_tag} ..."
            if tmpfile=$(get_release_info "$cand_tag"); then
                found_tag="$cand_tag"
                break
            fi
            [[ -n "$tmpfile" && -f "$tmpfile" ]] && rm -f "$tmpfile"
            tmpfile=""
        done
        [[ -z "$found_tag" ]] && die "未找到版本 ${TARGET_VERSION} 对应的 Release"
        tag="$found_tag"
        install_version="$TARGET_VERSION"
        [[ -n "$tmpfile" && -f "$tmpfile" ]] && rm -f "$tmpfile"
    else
        log_info "正在查询最新 release..."
        if ! tmpfile=$(get_release_info ""); then
            die "无法获取最新 release 信息"
        fi
        
        if [[ "$JSON_PARSER" == "jq" ]]; then
            tag=$(jq -r '.tag_name' "$tmpfile")
        else
            tag=$(python3 -c "import json; print(json.load(open('$tmpfile')).get('tag_name', ''))")
        fi
        rm -f "$tmpfile"
        
        local raw_version="$tag"
        for prefix in "$TAG_PREFIX" "v" "release-" "rel-" "version-"; do
            if [[ -n "$prefix" && "$raw_version" == "$prefix"* ]]; then
                raw_version="${raw_version#"$prefix"}"
                break
            fi
        done
        install_version="$raw_version"
        [[ -z "$install_version" ]] && die "无法提取版本号 (tag: $tag)"
    fi

    log_info "目标版本: ${install_version} (tag: ${tag})"

    local pkg_name
    pkg_name=$(detect_package_name)
    log_info "目标包名: ${pkg_name}"

    local current_version
    current_version=$(get_installed_version "$pkg_name")
    if [[ -n "$current_version" ]]; then
        log_success "当前已安装 ${pkg_name} 版本: ${current_version}"
    else
        log_warn "未安装 ${pkg_name}"
    fi

    if [[ -n "$current_version" && "$FORCE" -eq 0 ]]; then
        local cmp
        cmp=$(version_compare "$current_version" "$install_version")
        if [[ $cmp -eq 0 ]]; then
            log_success "已是最新版本 ($current_version)。如需重装请使用 -f 参数。"
            exit 0
        elif [[ $cmp -eq 1 ]]; then
            log_warn "当前版本 ($current_version) 高于目标版本 ($install_version)，准备降级..."
            read -r -p "确认降级安装？(y/N) " answer
            if [[ ! "$answer" =~ ^[Yy]$ ]]; then
                log_info "已取消。"
                exit 0
            fi
        else
            log_info "发现新版本: ${current_version:-无} → ${install_version}"
        fi
    fi

    log_info "正在查找 release ${tag} 中匹配架构的 .deb 包..."
    local download_url
    download_url=$(get_asset_url "$tag")
    log_info "下载地址: ${download_url}"

    # 使用缓存目录存放临时文件
    mkdir -p "$CACHE_DIR"
    local TEMP_DEB
    TEMP_DEB=$(mktemp "$CACHE_DIR/update_deb_XXXXXX.deb")
    trap '[[ -n "${TEMP_DEB:-}" && -f "${TEMP_DEB:-}" ]] && rm -f "$TEMP_DEB"' EXIT

    download_file "$download_url" "$TEMP_DEB"
    install_deb "$TEMP_DEB" "$pkg_name"
}

main "$@"