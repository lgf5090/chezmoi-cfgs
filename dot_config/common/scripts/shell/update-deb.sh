#!/usr/bin/env bash
#
# update-deb.sh — 从 GitHub Release 安装/升级/管理 .deb 包
#
# 功能：子命令式 CLI（install/uninstall/check/list/info）、智能架构匹配、
#       智能包名识别、jq 优先（回退 sed）、HTTP 超时、代理、缓存、断点续传、
#       sha256 校验、dry-run、日志级别、配置文件、非交互模式。
#
set -euo pipefail

# ======================== 默认配置 ========================
DEFAULT_REPO="esengine/DeepSeek-Reasonix"
DEFAULT_TAG_PREFIX="desktop-v"
DEFAULT_TIMEOUT=30
DEFAULT_CACHE_DIR="${HOME}/.cache/update-deb"
DEFAULT_CONFIG_FILE="${HOME}/.config/common/config/update-deb.conf"
DEFAULT_LIST_LIMIT=10

# ======================== 全局状态 ========================
REPO="$DEFAULT_REPO"
TARGET_VERSION=""
FORCE=0
MANUAL_PACKAGE=""
TAG_PREFIX="$DEFAULT_TAG_PREFIX"
ARCH_OVERRIDE=""
DRY_RUN=0
ASSUME_YES=0
PROXY=""
TIMEOUT="$DEFAULT_TIMEOUT"
CACHE_DIR="$DEFAULT_CACHE_DIR"
KEEP_CACHE=0
VERIFY_CHECKSUM=0
RESUME=0
NO_COLOR=0
QUIET=0
VERBOSE=0
CONFIG_FILE=""
LIST_LIMIT="$DEFAULT_LIST_LIMIT"
SUBCOMMAND="install"

# 多仓库支持：REPOS 数组（命令行 -r 可多次指定或逗号分隔）
declare -a REPOS=()

# 临时文件注册表（trap 清理用）
declare -a TEMP_FILES=()

# 颜色（用 $'...' 存入真实 ESC 字节，heredoc / echo / printf 均生效）
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
NC=$'\033[0m'

# ======================== 工具函数 ========================

cleanup() {
    if [[ ${#TEMP_FILES[@]} -gt 0 ]]; then
        rm -f "${TEMP_FILES[@]}" 2>/dev/null || true
    fi
}
trap cleanup EXIT

make_temp() {
    # make_temp [后缀] -> 创建临时文件并注册到清理表，输出路径
    local suffix="${1:-XXXXXX}"
    local f
    f=$(mktemp /tmp/update_deb_"${suffix}") || die "无法创建临时文件"
    TEMP_FILES+=("$f")
    echo "$f"
}

apply_color_policy() {
    # 非 TTY 或 --no-color 时关闭颜色
    if [[ ! -t 1 || "$NO_COLOR" -eq 1 ]]; then
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
    fi
}

log_debug() {
    [[ "$VERBOSE" -eq 1 ]] && echo -e "${CYAN}[debug]${NC} $*" >&2 || true
}
log_info() {
    [[ "$QUIET" -eq 0 ]] && echo -e "$*" >&2 || true
}
log_warn() {
    echo -e "${YELLOW}[警告]${NC} $*" >&2
}
log_error() {
    echo -e "${RED}[错误]${NC} $*" >&2
}
log_step() {
    [[ "$QUIET" -eq 0 ]] && echo -e "${BLUE}==>${NC} ${BOLD}$*${NC}" >&2 || true
}
die() {
    log_error "$*"
    exit 1
}

# 解析仓库列表：REPOS 为空时回退到 REPO
resolve_repos() {
    if [[ ${#REPOS[@]} -eq 0 ]]; then
        [[ -z "${REPO:-}" ]] && die "未指定仓库（用 -r/--repo 或配置文件设置 REPOS/REPO）"
        REPOS=("$REPO")
    fi
}

# 多仓库模式下仅 install/uninstall/list 可用，其余子命令禁用
check_single_repo_only() {
    if [[ ${#REPOS[@]} -gt 1 ]]; then
        die "多仓库模式下 '$SUBCOMMAND' 功能不可用（仅 install/uninstall/list 支持多仓库）"
    fi
}

confirm() {
    # confirm "提示语" -> 返回 0=是(继续), 1=否(取消)
    local prompt="$1"
    if [[ "$ASSUME_YES" -eq 1 || "$DRY_RUN" -eq 1 ]]; then
        log_info "${prompt} [y/N] y (自动确认)"
        return 0
    fi
    read -r -p "$(echo -e "${YELLOW}${prompt} [y/N]${NC} ")" answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# ======================== 配置文件 ========================

load_config() {
    local file="$CONFIG_FILE"
    [[ -z "$file" ]] && file="$DEFAULT_CONFIG_FILE"
    [[ -f "$file" ]] || return 0
    log_debug "加载配置文件: $file"
    # 安全地 source 配置（仅允许 KEY=VALUE 形式）
    while IFS='=' read -r key value; do
        key="${key%%#*}"           # 去注释
        key="$(echo "$key" | xargs)" # 去空白
        [[ -z "$key" ]] && continue
        value="${value%%#*}"
        value="$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")"
        case "$key" in
            REPO|TAG_PREFIX|CACHE_DIR|PROXY) eval "$key=\"\$value\"" ;;
            REPOS)
                # 逗号分隔的仓库列表
                IFS=',' read -ra _arr <<< "$value"
                REPOS=("${_arr[@]}") ;;
            TIMEOUT|LIST_LIMIT) eval "$key=\"\$value\"" ;;
            KEEP_CACHE|VERIFY_CHECKSUM|RESUME|NO_COLOR|QUIET|VERBOSE) eval "$key=\"\$value\"" ;;
            *) log_debug "配置文件忽略未知键: $key" ;;
        esac
    done < "$file"
}

# ======================== 代理 ========================

apply_proxy() {
    if [[ -n "$PROXY" ]]; then
        export http_proxy="$PROXY" https_proxy="$PROXY" HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY"
        log_debug "已设置代理: $PROXY"
    fi
}

# ======================== HTTP / API ========================

# 全局 HTTP 响应码
HTTP_CODE=""

# gh_api_get URL OUTPUT_FILE -> 请求 GitHub API，设置 HTTP_CODE
gh_api_get() {
    local url="$1" output="$2"
    local auth_args=()
    [[ -n "${GITHUB_TOKEN:-}" ]] && auth_args=(-H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json")

    if command -v curl &>/dev/null; then
        HTTP_CODE=$(curl -sL --max-time "$TIMEOUT" \
            "${auth_args[@]}" \
            -w "%{http_code}" -o "$output" "$url" 2>/dev/null) || HTTP_CODE="000"
    elif command -v wget &>/dev/null; then
        local out
        out=$(wget --timeout="$TIMEOUT" -q -S -O "$output" \
            ${GITHUB_TOKEN:+--header="Authorization: token ${GITHUB_TOKEN}"} \
            --header="Accept: application/vnd.github+json" "$url" 2>&1) || true
        HTTP_CODE=$(echo "$out" | grep -oP 'HTTP/\d\.\d \K\d{3}' | tail -1)
        [[ -z "$HTTP_CODE" ]] && HTTP_CODE="000"
    else
        die "需要 curl 或 wget（建议安装 curl）"
    fi
    log_debug "API GET $url -> HTTP $HTTP_CODE"
}

# http_download URL OUTPUT_FILE -> 下载文件（支持续传）
http_download() {
    local url="$1" output="$2"

    if command -v axel &>/dev/null && { [[ "$RESUME" -ne 1 ]] || [[ ! -f "$output" ]]; }; then
        # 非续传模式，或续传但文件不存在时用 axel
        log_info "${YELLOW}使用 axel 下载...${NC}"
        axel -n 4 -o "$output" "$url" && return
        log_warn "axel 下载失败，回退到其他工具"
    fi

    if [[ "$RESUME" -eq 1 && -f "$output" ]]; then
        # 续传模式：优先 curl/wget（支持 -C - / -c）
        if command -v wget &>/dev/null; then
            log_info "${YELLOW}使用 wget 续传...${NC}"
            local w_flags=(-q --show-progress --timeout="$TIMEOUT" --tries=3 -c)
            wget "${w_flags[@]}" -O "$output" "$url" || die "wget 续传失败"
        elif command -v curl &>/dev/null; then
            log_info "${YELLOW}使用 curl 续传...${NC}"
            local c_flags=(-L --max-time 0 --connect-timeout "$TIMEOUT" --retry 3 --retry-delay 2 -C -)
            curl "${c_flags[@]}" -o "$output" "$url" || {
                local rc=$?
                [[ "$rc" -eq 33 ]] || die "curl 续传失败 (exit $rc)"
            }
        else
            die "续传需要 curl 或 wget"
        fi
        return
    fi

    if command -v aria2c &>/dev/null; then
        log_info "${YELLOW}使用 aria2c 下载...${NC}"
        local a_flags=(-x 4 -s 4 --max-tries=3 --retry-wait=2)
        [[ "$RESUME" -eq 1 ]] && a_flags+=(-c)
        aria2c "${a_flags[@]}" -d "$(dirname "$output")" -o "$(basename "$output")" "$url" || die "aria2c 下载失败"
    elif command -v wget &>/dev/null; then
        log_info "${YELLOW}使用 wget 下载...${NC}"
        local w_flags=(-q --show-progress --timeout="$TIMEOUT" --tries=3)
        [[ "$RESUME" -eq 1 ]] && w_flags+=(-c)
        wget "${w_flags[@]}" -O "$output" "$url" || die "wget 下载失败"
    elif command -v curl &>/dev/null; then
        log_info "${YELLOW}使用 curl 下载...${NC}"
        local c_flags=(-L --max-time 0 --connect-timeout "$TIMEOUT" --retry 3 --retry-delay 2)
        [[ "$RESUME" -eq 1 ]] && c_flags+=(-C -)
        # curl -C - 对已完整文件返回 33 (HTTP range error)，视为成功
        curl "${c_flags[@]}" -o "$output" "$url" || {
            local rc=$?
            [[ "$rc" -eq 33 ]] || die "curl 下载失败 (exit $rc)"
        }
    else
        die "未找到可用下载工具（axel/aria2c/wget/curl）"
    fi
}

# ======================== JSON 解析（jq 优先，回退 sed） ========================

has_jq() { command -v jq &>/dev/null; }

# json_field FILE FIELD -> 提取顶层字符串字段
json_field() {
    local file="$1" field="$2"
    if has_jq; then
        jq -r --arg f "$field" '.[$f] // empty' "$file" 2>/dev/null
    else
        sed -n "s/.*\"$field\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$file" | head -1
    fi
}

# json_tag FILE -> 提取 tag_name
json_tag() { json_field "$1" "tag_name"; }

# json_assets FILE -> 输出每行: NAME<TAB>URL<TAB>DIGEST<TAB>SIZE（仅 .deb）
json_assets() {
    local file="$1"
    if has_jq; then
        jq -r '.assets[] | select(.name | endswith(".deb")) | "\(.name)\t\(.browser_download_url)\t\(.digest // empty)\t\(.size // 0)"' "$file" 2>/dev/null
    else
        # 回退：用 grep 逐行提取 browser_download_url
        grep -i '"browser_download_url"' "$file" | while IFS= read -r line; do
            local url name
            url=$(echo "$line" | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            [[ -z "$url" ]] && continue
            [[ "$url" =~ \.deb$ ]] || continue
            name=$(basename "$url")
            printf '%s\t%s\t\t0\n' "$name" "$url"
        done
    fi
}

# json_all_assets FILE -> 输出每行: NAME<TAB>URL<TAB>SIZE<TAB>DOWNLOADS（所有类型）
json_all_assets() {
    local file="$1"
    if has_jq; then
        jq -r '.assets[] | "\(.name)\t\(.browser_download_url)\t\(.size // 0)\t\(.download_count // 0)"' "$file" 2>/dev/null
    else
        # 回退：grep 提取 name 和 url
        grep -iE '"(name|browser_download_url)"' "$file" | paste - - 2>/dev/null | while IFS=$'\t' read -r name_line url_line; do
            local name url
            name=$(echo "$name_line" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            url=$(echo "$url_line" | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            [[ -z "$name" || -z "$url" ]] && continue
            printf '%s\t%s\t0\t0\n' "$name" "$url"
        done
    fi
}

# json_release_tags FILE -> 输出每行: TAG<TAB>NAME<TAB>PRERELEASE<TAB>PUBLISHED
json_release_tags() {
    local file="$1"
    if has_jq; then
        jq -r '.[] | "\(.tag_name)\t\(.name // "")\t\(.prerelease // false)\t\(.published_at // "")"' "$file" 2>/dev/null
    else
        # 回退：提取所有 tag_name
        grep -oP '"tag_name"[[:space:]]*:[[:space:]]*"\K[^"]*' "$file" 2>/dev/null || true
    fi
}

# ======================== 架构 ========================

detect_arch() {
    if [[ -n "$ARCH_OVERRIDE" ]]; then
        echo "$ARCH_OVERRIDE"
        return
    fi
    dpkg --print-architecture 2>/dev/null || uname -m
}

declare -A ARCH_ALIASES
ARCH_ALIASES[amd64]="x86_64 x64"
ARCH_ALIASES[arm64]="aarch64 arm64v8"
ARCH_ALIASES[armhf]="armv7l"
ARCH_ALIASES[i386]="i686 x86"
ARCH_ALIASES[riscv64]=""

# 非规范简写（需分隔符边界匹配，避免版本号误匹配）
declare -A ARCH_SHORTHAND
ARCH_SHORTHAND[amd64]="64"
ARCH_SHORTHAND[i386]="32"

arch_pattern() {
    # 输出用于 grep 的架构匹配模式 (a|b|c)
    local arch="$1"
    local -a ids=("$arch")
    if [[ -n "${ARCH_ALIASES[$arch]:-}" ]]; then
        for a in ${ARCH_ALIASES[$arch]}; do ids+=("$a"); done
    fi
    local IFS='|'
    echo "${ids[*]}"
}

# arch_match_name ARCH FILENAME -> 0/1
# 两阶段匹配：标准架构名 -> 带边界的简写
arch_match_name() {
    local arch="$1" name="$2"
    local pattern; pattern=$(arch_pattern "$arch")
    # 阶段1：标准架构名/别名（大小写不敏感）
    if echo "$name" | grep -iqE "($pattern)"; then
        return 0
    fi
    # 阶段2：简写匹配（前后需为分隔符或边界，避免版本号误匹配）
    local sh="${ARCH_SHORTHAND[$arch]:-}"
    if [[ -n "$sh" ]] && echo "$name" | grep -iqE "(^|[-_])${sh}($|[-_.])"; then
        return 0
    fi
    return 1
}

# ======================== 包名识别 ========================

detect_package_name() {
    if [[ -n "$MANUAL_PACKAGE" ]]; then
        echo "$MANUAL_PACKAGE"
        return
    fi

    local repo_slug
    repo_slug=$(echo "$REPO" | awk -F'/' '{print $2}')

    local installed_pkgs
    installed_pkgs=$(dpkg-query -W -f='${Package}\n' 2>/dev/null) || installed_pkgs=""

    # 1. 精确包含（忽略大小写）
    local exact
    exact=$(echo "$installed_pkgs" | grep -i -F "$repo_slug" | head -1) || true
    if [[ -n "$exact" ]]; then
        echo "$exact"
        return
    fi

    # 2. 拆分单词：连字符/下划线 + 驼峰边界
    local normalized
    normalized=$(echo "$repo_slug" \
        | sed 's/[-_]/ /g' \
        | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g' \
        | tr '[:upper:]' '[:lower:]')
    local words=()
    for w in $normalized; do
        [[ -n "$w" ]] && words+=("$w")
    done

    if [[ ${#words[@]} -gt 0 ]]; then
        local candidate=""
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
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
        done <<< "$installed_pkgs"
        if [[ -n "$candidate" ]]; then
            echo "$candidate"
            return
        fi
    fi

    # 3. 回退映射 / 小写 slug
    local lower_slug
    lower_slug=$(echo "$repo_slug" | tr '[:upper:]' '[:lower:]')
    case "$lower_slug" in
        deepseek-reasonix) echo "reasonix-desktop" ;;
        cc-switch)         echo "cc-switch" ;;
        *)                 echo "$lower_slug" ;;
    esac
}

get_installed_version() {
    local pkg="$1" ver
    ver=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null) || true
    echo "${ver:-}"
}

is_package_installed() {
    local pkg="$1"
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

# ======================== 版本比较 ========================

version_lt() {
    # version_lt A B -> A < B ?
    local a="$1" b="$2"
    if command -v dpkg &>/dev/null; then
        dpkg --compare-versions "$a" lt "$b" 2>/dev/null
    else
        local first
        first=$(printf '%s\n%s\n' "$a" "$b" | sort -V | head -1)
        [[ "$first" == "$a" && "$a" != "$b" ]]
    fi
}

version_eq() {
    local a="$1" b="$2"
    if command -v dpkg &>/dev/null; then
        dpkg --compare-versions "$a" eq "$b" 2>/dev/null
    else
        [[ "$a" == "$b" ]]
    fi
}

# 去除 epoch 与 deb 修订号，提取纯上游版本用于比较
normalize_version() {
    local v="$1"
    v="${v%%-*}"        # 去掉 -debrev
    v="${v#*:}"         # 去掉 epoch:
    echo "$v"
}

# ======================== Release / Tag ========================

get_latest_release() {
    # 输出 tag_name，失败 die
    local api_url="https://api.github.com/repos/${REPO}/releases/latest"
    local tmp; tmp=$(make_temp "api_XXXXXX")
    gh_api_get "$api_url" "$tmp"
    [[ "$HTTP_CODE" != "200" ]] && die "GitHub API 返回 HTTP $HTTP_CODE（仓库 $REPO 可能不存在或无 release）"
    local tag; tag=$(json_tag "$tmp")
    [[ -z "$tag" ]] && die "无法解析 tag_name"
    echo "$tag"
}

get_release_by_tag() {
    # get_release_by_tag TAG -> 输出 release JSON 文件路径
    local tag="$1"
    local api_url="https://api.github.com/repos/${REPO}/releases/tags/${tag}"
    local tmp; tmp=$(make_temp "rel_XXXXXX")
    gh_api_get "$api_url" "$tmp"
    if [[ "$HTTP_CODE" != "200" ]]; then
        return 1
    fi
    echo "$tmp"
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

extract_version_from_tag() {
    local tag="$1"
    if [[ -n "$TAG_PREFIX" && "$tag" =~ ^${TAG_PREFIX}(.+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$tag" =~ ^v(.+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "$tag"
    fi
}

# ======================== 资产匹配 ========================

# find_deb_asset RELEASE_FILE -> 输出: URL<TAB>NAME<TAB>DIGEST（匹配架构）
find_deb_asset() {
    local release_file="$1"
    local arch; arch=$(detect_arch)

    local matched_url="" matched_name="" matched_digest=""
    local deb_list=()

    while IFS=$'\t' read -r name url digest; do
        [[ -z "$url" ]] && continue
        deb_list+=("$name")
        if arch_match_name "$arch" "$name"; then
            matched_url="$url"
            matched_name="$name"
            matched_digest="$digest"
            break
        fi
    done < <(json_assets "$release_file")

    if [[ -z "$matched_url" ]]; then
        log_warn "未找到匹配架构 [${arch}] 的 .deb 包"
        if [[ ${#deb_list[@]} -gt 0 ]]; then
            log_warn "Release 中可用的 .deb 资产:"
            for n in "${deb_list[@]}"; do
                echo "  - $n" >&2
            done
        else
            log_warn "Release 中没有任何 .deb 资产"
        fi
        return 1
    fi

    printf '%s\t%s\t%s\n' "$matched_url" "$matched_name" "$matched_digest"
}

# ======================== 下载 + 缓存 + 校验 ========================

cache_path_for() {
    # cache_path_for NAME -> 缓存文件路径
    local name="$1"
    local repo_slug; repo_slug=$(echo "$REPO" | tr '/' '_')
    echo "${CACHE_DIR}/${repo_slug}_${name}"
}

verify_sha256() {
    # verify_sha256 FILE EXPECTED -> 0/1
    local file="$1" expected="$2"
    expected="${expected#sha256:}"   # 去掉 sha256: 前缀
    expected="${expected,,}"         # 转小写
    local actual
    if command -v sha256sum &>/dev/null; then
        actual=$(sha256sum "$file" | awk '{print $1}')
    elif command -v shasum &>/dev/null; then
        actual=$(shasum -a 256 "$file" | awk '{print $1}')
    else
        log_warn "无 sha256sum/shasum，跳过校验"
        return 0
    fi
    [[ "${actual,,}" == "$expected" ]]
}

fetch_deb() {
    # fetch_deb URL NAME DIGEST -> 输出本地文件路径
    local url="$1" name="$2" digest="${3:-}"
    mkdir -p "$CACHE_DIR" || die "无法创建缓存目录: $CACHE_DIR"
    local cached; cached=$(cache_path_for "$name")

    # 命中缓存
    if [[ -f "$cached" ]]; then
        log_debug "缓存命中: $cached"
        if [[ -n "$digest" && "$VERIFY_CHECKSUM" -eq 1 ]]; then
            if verify_sha256 "$cached" "$digest"; then
                log_info "${GREEN}缓存校验通过，复用: ${cached}${NC}"
                echo "$cached"
                return
            else
                log_warn "缓存校验失败，重新下载"
                rm -f "$cached"
            fi
        elif [[ "$RESUME" -eq 1 ]]; then
            # 续传模式：保留部分文件，交给下载工具续传
            log_info "${YELLOW}续传模式，继续下载: ${cached}${NC}"
            # 不 return，继续走下载逻辑
        else
            log_info "${GREEN}复用缓存: ${cached}${NC}（未校验，--verify-checksum 可启用）"
            echo "$cached"
            return
        fi
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "${YELLOW}[dry-run] 将下载 ${url} -> ${cached}${NC}"
        echo "$cached"
        return
    fi

    http_download "$url" "$cached"

    # 校验
    if [[ -n "$digest" && "$VERIFY_CHECKSUM" -eq 1 ]]; then
        log_step "校验 sha256..."
        if ! verify_sha256 "$cached" "$digest"; then
            rm -f "$cached"
            die "sha256 校验失败: $cached"
        fi
        log_info "${GREEN}sha256 校验通过${NC}"
    elif [[ -n "$digest" ]]; then
        log_debug "资产提供 digest，但未启用 --verify-checksum"
    fi

    echo "$cached"
}

# ======================== 安装/卸载 ========================

dpkg_install() {
    local deb="$1"
    local deb_abs; deb_abs=$(readlink -f "$deb")
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "${YELLOW}[dry-run] 将执行: apt-get install ${deb_abs} -y${NC}"
        return
    fi
    log_step "安装中..."

    # apt-get 选项：自动处理依赖、允许降级
    local apt_opts=(-y --allow-downgrades --allow-remove-essential --allow-change-held-packages)
    local sudo_prefix=()
    [[ $EUID -ne 0 ]] && sudo_prefix=(sudo)

    # 优先用 apt-get install ./file.deb（自动解析并下载依赖）
    if command -v apt-get &>/dev/null; then
        log_debug "使用 apt-get install 安装（自动处理依赖）"
        if "${sudo_prefix[@]}" apt-get install "${apt_opts[@]}" "$deb_abs"; then
            return 0
        fi
        log_warn "apt-get 安装失败，回退到 dpkg + 依赖修复"
    fi

    # 回退：dpkg -i + apt-get install -f -y
    if "${sudo_prefix[@]}" dpkg -i "$deb"; then
        return 0
    fi
    log_warn "dpkg 报告依赖问题，尝试修复..."
    "${sudo_prefix[@]}" apt-get install -f -y || die "依赖修复失败"
}

dpkg_remove() {
    local pkg="$1"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "${YELLOW}[dry-run] 将执行: dpkg -r ${pkg}${NC}"
        return
    fi
    log_step "卸载中..."
    if [[ $EUID -ne 0 ]]; then
        sudo dpkg -r "$pkg" || die "dpkg 卸载失败"
    else
        dpkg -r "$pkg" || die "dpkg 卸载失败"
    fi
}

# ======================== 子命令: install ========================

cmd_install() {
    resolve_repos
    local total=${#REPOS[@]} idx=0
    # 多仓库模式仅支持安装最新版
    if [[ $total -gt 1 && -n "$TARGET_VERSION" ]]; then
        log_warn "多仓库模式仅支持安装最新版，忽略 -v ${TARGET_VERSION}"
        TARGET_VERSION=""
    fi
    declare -a failed=()
    for r in "${REPOS[@]}"; do
        idx=$((idx + 1))
        REPO="$r"
        if [[ $total -gt 1 ]]; then
            echo -e "\n${BOLD}==> [$idx/$total] 仓库: ${REPO}${NC}" >&2
        fi
        # 子 shell 隔离：单个仓库失败（die/exit）不影响后续仓库
        ( trap cleanup EXIT; _install_one_repo ) || failed+=("$REPO")
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "以下仓库安装失败: ${failed[*]}"
        exit 1
    fi
}

_install_one_repo() {
    echo -e "仓库: ${BOLD}${REPO}${NC}"
    echo -e "系统架构: ${ARCH}"
    [[ -n "$TAG_PREFIX" ]] && echo -e "Tag 前缀: \"${TAG_PREFIX}\"" || echo -e "Tag 前缀: (无)"
    [[ "$DRY_RUN" -eq 1 ]] && log_info "${YELLOW}[dry-run 模式] 不会实际下载/安装${NC}"

    local install_version="" tag="" release_file=""

    if [[ -n "$TARGET_VERSION" ]]; then
        local found_tag="" found_file=""
        for cand_tag in $(get_possible_tags "$TARGET_VERSION"); do
            log_info "尝试 tag: ${cand_tag} ..."
            if found_file=$(get_release_by_tag "$cand_tag"); then
                found_tag="$cand_tag"
                break
            fi
        done
        [[ -z "$found_tag" ]] && die "未找到版本 ${TARGET_VERSION} 对应的 release"
        tag="$found_tag"
        release_file="$found_file"
        install_version="$TARGET_VERSION"
    else
        log_step "查询最新 release..."
        tag=$(get_latest_release)
        release_file=$(get_release_by_tag "$tag") || die "无法获取 release ${tag}"
        install_version=$(extract_version_from_tag "$tag")
        [[ -z "$install_version" ]] && die "无法从 tag (${tag}) 提取版本号"
    fi

    echo -e "目标版本: ${BOLD}${install_version}${NC} (tag: ${tag})"

    local pkg_name; pkg_name=$(detect_package_name)
    echo -e "目标包名: ${BOLD}${pkg_name}${NC}"

    local current_version; current_version=$(get_installed_version "$pkg_name")
    if [[ -n "$current_version" ]]; then
        echo -e "${GREEN}当前已安装 ${pkg_name} 版本: ${current_version}${NC}"
    else
        echo -e "${YELLOW}未安装 ${pkg_name}${NC}"
    fi

    # 版本判断
    if [[ -n "$current_version" && "$FORCE" -eq 0 ]]; then
        local cur_norm inst_norm
        cur_norm=$(normalize_version "$current_version")
        inst_norm=$(normalize_version "$install_version")
        if version_eq "$cur_norm" "$inst_norm"; then
            log_info "${GREEN}已是最新版本。重装请加 -f/--force${NC}"
            exit 0
        fi
        if version_lt "$cur_norm" "$inst_norm"; then
            echo -e "发现新版本: ${current_version} → ${install_version}"
        else
            if ! confirm "当前版本 (${current_version}) 高于目标 (${install_version})，确认降级？"; then
                log_info "已取消。"
                exit 0
            fi
        fi
    fi

    # 查找资产
    log_step "查找 release ${tag} 中匹配架构的 .deb..."
    local asset_line asset_url asset_name asset_digest
    asset_line=$(find_deb_asset "$release_file") || die "自动匹配 .deb 失败"
    IFS=$'\t' read -r asset_url asset_name asset_digest <<< "$asset_line"
    echo -e "下载资产: ${asset_name}"
    log_debug "URL: ${asset_url}"
    [[ -n "$asset_digest" ]] && log_debug "digest: ${asset_digest}"

    local deb_file
    deb_file=$(fetch_deb "$asset_url" "$asset_name" "$asset_digest")

    log_info "${YELLOW}安装 ${pkg_name} ${install_version}...${NC}"
    dpkg_install "$deb_file"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        : # dry-run 模式，不处理缓存
    elif [[ "$KEEP_CACHE" -eq 0 ]]; then
        rm -f "$deb_file" 2>/dev/null || true
        log_debug "已清理缓存文件: $deb_file"
    else
        log_info "${GREEN}缓存已保留: ${deb_file}${NC}"
    fi

    log_info "${GREEN}安装完成！${NC}"
}

# ======================== 子命令: uninstall ========================

cmd_uninstall() {
    resolve_repos
    local total=${#REPOS[@]} idx=0
    declare -a failed=()
    for r in "${REPOS[@]}"; do
        idx=$((idx + 1))
        REPO="$r"
        if [[ $total -gt 1 ]]; then
            echo -e "\n${BOLD}==> [$idx/$total] 仓库: ${REPO}${NC}" >&2
        fi
        ( trap cleanup EXIT; _uninstall_one_repo ) || failed+=("$REPO")
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "以下仓库卸载失败: ${failed[*]}"
        exit 1
    fi
}

_uninstall_one_repo() {
    local pkg_name; pkg_name=$(detect_package_name)
    echo -e "目标包名: ${BOLD}${pkg_name}${NC}"

    if ! is_package_installed "$pkg_name"; then
        log_warn "${pkg_name} 未安装，无需卸载"
        exit 0
    fi

    local current_version; current_version=$(get_installed_version "$pkg_name")
    echo -e "已安装版本: ${current_version}"

    if ! confirm "确认卸载 ${pkg_name}？"; then
        log_info "已取消。"
        exit 0
    fi

    dpkg_remove "$pkg_name"
    log_info "${GREEN}卸载完成！${NC}"
}

# ======================== 子命令: check ========================

# 退出码: 0=最新, 1=有更新, 2=未安装, 3=出错
cmd_check() {
    check_single_repo_only
    local pkg_name; pkg_name=$(detect_package_name)
    local current_version; current_version=$(get_installed_version "$pkg_name")

    log_step "查询最新 release..."
    local tag; tag=$(get_latest_release)
    local latest_version; latest_version=$(extract_version_from_tag "$tag")

    if [[ -z "$current_version" ]]; then
        echo -e "${YELLOW}${pkg_name} 未安装${NC}（最新版: ${latest_version}）"
        exit 2
    fi

    local cur_norm inst_norm
    cur_norm=$(normalize_version "$current_version")
    inst_norm=$(normalize_version "$latest_version")

    if version_eq "$cur_norm" "$inst_norm"; then
        echo -e "${GREEN}${pkg_name} 已是最新版本: ${current_version}${NC}"
        exit 0
    elif version_lt "$cur_norm" "$inst_norm"; then
        echo -e "${YELLOW}有可用更新: ${pkg_name} ${current_version} → ${latest_version}${NC}"
        exit 1
    else
        echo -e "${BLUE}已安装版本 (${current_version}) 高于最新 release (${latest_version})${NC}"
        exit 0
    fi
}

# ======================== 子命令: list ========================

cmd_list() {
    resolve_repos
    local total=${#REPOS[@]} idx=0
    declare -a failed=()
    for r in "${REPOS[@]}"; do
        idx=$((idx + 1))
        REPO="$r"
        if [[ $total -gt 1 ]]; then
            echo -e "\n${BOLD}==> [$idx/$total] 仓库: ${REPO}${NC}" >&2
        fi
        ( trap cleanup EXIT; _list_one_repo ) || failed+=("$REPO")
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "以下仓库查询失败: ${failed[*]}"
        exit 1
    fi
}

_list_one_repo() {
    local limit="$LIST_LIMIT"
    local header_limit="$limit"
    if [[ "$limit" -le 0 ]]; then
        limit=100
        header_limit="所有"
    fi
    local api_url="https://api.github.com/repos/${REPO}/releases?per_page=${limit}"
    local tmp; tmp=$(make_temp "list_XXXXXX")
    gh_api_get "$api_url" "$tmp"
    [[ "$HTTP_CODE" != "200" ]] && die "GitHub API 返回 HTTP $HTTP_CODE"

    echo -e "${BOLD}最近 ${header_limit} 个 release（${REPO}）:${NC}"
    printf '%-4s %-24s %-10s %-22s %s\n' "#" "Tag" "Pre" "Published" "Name"

    local idx=0
    if has_jq; then
        while IFS=$'\t' read -r t name pre pub; do
            idx=$((idx + 1))
            local pre_mark="-"
            [[ "$pre" == "true" ]] && pre_mark="pre"
            local pub_short="${pub%%T*}"
            printf '%-4s %-24s %-10s %-22s %s\n' "$idx" "$t" "$pre_mark" "$pub_short" "$name"
        done < <(json_release_tags "$tmp")
    else
        # sed 回退：仅输出 tag
        while IFS= read -r t; do
            idx=$((idx + 1))
            printf '%-4s %-24s %-10s %-22s %s\n' "$idx" "$t" "-" "-" "-"
        done < <(json_release_tags "$tmp")
    fi

    if [[ $idx -eq 0 ]]; then
        log_warn "未找到任何 release"
    fi
}

# ======================== 子命令: list-assets / list-deb ========================

# 获取目标 release 的 JSON 文件（返回临时文件路径到 stdout）
_fetch_release_file() {
    local tag="" release_file=""
    if [[ -n "$TARGET_VERSION" ]]; then
        local found_tag=""
        for cand_tag in $(get_possible_tags "$TARGET_VERSION"); do
            log_info "尝试 tag: ${cand_tag} ..."
            if release_file=$(get_release_by_tag "$cand_tag"); then
                found_tag="$cand_tag"
                break
            fi
        done
        [[ -z "$found_tag" ]] && die "未找到版本 ${TARGET_VERSION} 对应的 release"
        tag="$found_tag"
    else
        log_step "查询最新 release..."
        tag=$(get_latest_release) || die "无法获取最新 release"
        release_file=$(get_release_by_tag "$tag") || die "无法获取 release ${tag}"
    fi
    echo -e "目标: ${BOLD}${tag}${NC}" >&2
    echo "$release_file"
}

# 列出指定 release 的所有 assets
cmd_list_assets() {
    resolve_repos
    local total=${#REPOS[@]} idx=0
    declare -a failed=()
    for r in "${REPOS[@]}"; do
        idx=$((idx + 1))
        REPO="$r"
        if [[ $total -gt 1 ]]; then
            echo -e "\n${BOLD}==> [$idx/$total] 仓库: ${REPO}${NC}" >&2
        fi
        ( trap cleanup EXIT; _list_assets_one_repo ) || failed+=("$REPO")
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "以下仓库查询失败: ${failed[*]}"
        exit 1
    fi
}

_list_assets_one_repo() {
    local release_file; release_file=$(_fetch_release_file)
    local tag; tag=$(json_tag "$release_file")
    local release_name; release_name=$(json_field "$release_file" "name")
    local pub; pub=$(json_field "$release_file" "published_at")

    echo -e "${BOLD}== ${REPO} @ ${tag} ==${NC}"
    [[ -n "$release_name" ]] && echo -e "  Release:    ${release_name}"
    [[ -n "$pub" ]] && echo -e "  发布时间:   ${pub%%T*}"
    echo -e "  所有资产:${NC}"
    echo

    printf '  %-40s %-12s %-10s %s\n' "名称" "大小" "下载量" "URL"
    printf '  %-40s %-12s %-10s %s\n' "$(printf '%0.s-' {1..40})" "------------" "----------" "-----------------------------------"

    local idx=0
    while IFS=$'\t' read -r name url size dl; do
        idx=$((idx + 1))
        local size_h
        if [[ "$size" -ge 1048576 ]]; then
            size_h=$(awk "BEGIN{printf \"%.1fM\", ${size}/1048576}")
        elif [[ "$size" -ge 1024 ]]; then
            size_h=$(awk "BEGIN{printf \"%.1fK\", ${size}/1024}")
        else
            size_h="${size}B"
        fi
        printf '  %-40s %-12s %-10s %s\n' "$name" "$size_h" "$dl" "$url"
    done < <(json_all_assets "$release_file")

    if [[ $idx -eq 0 ]]; then
        log_warn "此 release 没有任何资产"
    else
        echo
        echo -e "  共 ${idx} 个资产"
    fi
}

# 列出指定 release 的 .deb 资产（标记架构匹配）
cmd_list_deb() {
    resolve_repos
    local total=${#REPOS[@]} idx=0
    declare -a failed=()
    for r in "${REPOS[@]}"; do
        idx=$((idx + 1))
        REPO="$r"
        if [[ $total -gt 1 ]]; then
            echo -e "\n${BOLD}==> [$idx/$total] 仓库: ${REPO}${NC}" >&2
        fi
        ( trap cleanup EXIT; _list_deb_one_repo ) || failed+=("$REPO")
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "以下仓库查询失败: ${failed[*]}"
        exit 1
    fi
}

_list_deb_one_repo() {
    local release_file; release_file=$(_fetch_release_file)
    local tag; tag=$(json_tag "$release_file")
    local arch; arch=$(detect_arch)

    echo -e "${BOLD}== ${REPO} @ ${tag} ==${NC}"
    echo -e "  当前架构:   ${arch}"
    echo -e "  .deb 资产:${NC}"
    echo

    printf '  %-6s %-40s %-10s %-12s %s\n' "匹配" "名称" "大小" "sha256" "URL"
    printf '  %-6s %-40s %-10s %-12s %s\n' "------" "$(printf '%0.s-' {1..40})" "----------" "------------" "-----------------------------------"

    local idx=0
    while IFS=$'\t' read -r name url digest size; do
        idx=$((idx + 1))
        local match="  -"
        if arch_match_name "$arch" "$name"; then
            match="${GREEN}  ✓${NC}"
        fi
        local size_h
        if [[ "${size:-0}" -ge 1048576 ]]; then
            size_h=$(awk "BEGIN{printf \"%.1fM\", ${size}/1048576}")
        elif [[ "${size:-0}" -ge 1024 ]]; then
            size_h=$(awk "BEGIN{printf \"%.1fK\", ${size}/1024}")
        else
            size_h="${size:-0}B"
        fi
        local digest_short="-"
        [[ -n "$digest" ]] && digest_short="${digest#sha256:}" && digest_short="${digest_short:0:12}..."
        printf '  %b %-40s %-10s %-12s %s\n' "$match" "$name" "$size_h" "$digest_short" "$url"
    done < <(json_assets "$release_file")

    if [[ $idx -eq 0 ]]; then
        log_warn "此 release 没有 .deb 资产"
    else
        echo
        echo -e "  共 ${idx} 个 .deb（${GREEN}✓${NC} = 匹配当前架构 ${arch}）"
    fi
}

# ======================== 子命令: info ========================

cmd_info() {
    check_single_repo_only
    local pkg_name; pkg_name=$(detect_package_name)
    local current_version; current_version=$(get_installed_version "$pkg_name")

    echo -e "${BOLD}== ${REPO} ==${NC}"
    echo -e "  仓库:        ${REPO}"
    echo -e "  Tag 前缀:    ${TAG_PREFIX:-(无)}"
    echo -e "  系统架构:    ${ARCH}"
    echo -e "  识别包名:    ${pkg_name}"
    if [[ -n "$current_version" ]]; then
        echo -e "  已安装版本:  ${GREEN}${current_version}${NC}"
    else
        echo -e "  已安装版本:  ${YELLOW}未安装${NC}"
    fi

    log_step "查询最新 release..."
    if tag=$(get_latest_release 2>/dev/null); then
        local latest_version; latest_version=$(extract_version_from_tag "$tag")
        echo -e "  最新版本:    ${latest_version} (tag: ${tag})"
        if [[ -n "$current_version" ]]; then
            local cur_norm inst_norm
            cur_norm=$(normalize_version "$current_version")
            inst_norm=$(normalize_version "$latest_version")
            if version_eq "$cur_norm" "$inst_norm"; then
                echo -e "  状态:        ${GREEN}已是最新${NC}"
            elif version_lt "$cur_norm" "$inst_norm"; then
                echo -e "  状态:        ${YELLOW}有更新可用${NC}"
            else
                echo -e "  状态:        ${BLUE}高于最新 release${NC}"
            fi
        fi
    else
        echo -e "  最新版本:    ${RED}查询失败${NC}"
    fi
}

# ======================== 帮助 ========================

usage() {
    cat <<EOF
${BOLD}update-deb.sh${NC} — 从 GitHub Release 安装/升级/管理 .deb 包

${BOLD}用法:${NC}
  $0 [子命令] [选项] [参数]
  若不指定子命令，默认为 ${CYAN}install${NC}。

${BOLD}子命令:${NC}
  install (默认)   安装或升级 .deb 包
  uninstall        卸载已安装的包
  check            仅检查是否有新版本（不安装）
                   退出码: 0=最新, 1=有更新, 2=未安装, 3=出错
  list             列出最近的 release 版本
  list-assets      列出指定 release 的所有资产（所有类型文件）
  list-deb         列出指定 release 的 .deb 资产（标记架构匹配）
  info             显示已安装版本与最新版本信息

${BOLD}通用选项:${NC}
  -r, --repo REPO          目标 GitHub 仓库 (owner/repo)，可多次指定或逗号分隔
                           (默认: ${DEFAULT_REPO})
                           多仓库示例: -r a/b,c/d  或  -r a/b -r c/d
                           多仓库支持: install/uninstall/list/list-assets/list-deb
                           多仓库不支持: check/info
  -v, --version VERSION    指定版本 (如 1.2.3)，默认安装最新版
  -f, --force              强制安装，即使已安装相同版本
  -p, --package NAME       手动指定已安装的包名
  --tag-prefix PREFIX      release tag 前缀
                           (默认: "${DEFAULT_TAG_PREFIX}")
  --arch ARCH              覆盖系统架构检测
  --limit N                list 子命令显示条数 (默认: ${DEFAULT_LIST_LIMIT})

${BOLD}执行控制:${NC}
  --dry-run                预演模式，不实际下载/安装/卸载
  -y, --yes                自动确认所有交互提示
  --timeout SECS           HTTP 超时秒数 (默认: ${DEFAULT_TIMEOUT})

${BOLD}网络:${NC}
  --proxy URL              设置 HTTP/HTTPS 代理 (如 http://127.0.0.1:2080)
                           亦支持 http_proxy/https_proxy 环境变量

${BOLD}缓存与校验:${NC}
  --cache-dir DIR          缓存目录 (默认: ${DEFAULT_CACHE_DIR})
  --keep-cache             下载后保留缓存文件
  --verify-checksum        校验 sha256（若 release 资产提供 digest）
  --resume                 断点续传下载

${BOLD}输出:${NC}
  --no-color               禁用彩色输出
  -q, --quiet              静默模式（仅输出错误/警告）
  -V, --verbose            详细调试输出
  --config FILE            指定配置文件 (默认: ${DEFAULT_CONFIG_FILE})
  -h, --help               显示此帮助

${BOLD}配置文件:${NC}
  支持 KEY=VALUE 格式，可配置: REPO, TAG_PREFIX, CACHE_DIR, PROXY,
  TIMEOUT, LIST_LIMIT, KEEP_CACHE, VERIFY_CHECKSUM, RESUME, NO_COLOR,
  QUIET, VERBOSE。行首 # 为注释。

${BOLD}环境变量:${NC}
  GITHUB_TOKEN             GitHub API 认证 token（提高速率限制）
  http_proxy/https_proxy   代理地址

${BOLD}下载工具优先级:${NC} axel → aria2c → wget → curl

${BOLD}示例:${NC}

  # 默认安装最新版
  $0
  $0 install

  # 指定仓库和版本
  $0 -r edison7009/EchoBird --tag-prefix "v" -v 1.2.3
  $0 install -r farion1231/cc-switch -v 3.16.3 --tag-prefix ""

  # 多仓库批量安装最新版（逗号分隔 或 多次 -r）
  $0 install -r esengine/DeepSeek-Reasonix,2dust/v2rayN --tag-prefix ""
  $0 install -r esengine/DeepSeek-Reasonix -r 2dust/v2rayN --tag-prefix ""
  $0 install --dry-run -r a/b,c/d --proxy http://127.0.0.1:2080

  # 多仓库批量卸载
  $0 uninstall -r esengine/DeepSeek-Reasonix,edison7009/EchoBird --tag-prefix ""

  # 多仓库列出 release（每个仓库分别列出）
  $0 list -r a/b,c/d --limit 5

  # 仅检查更新（适合脚本/cron）
  $0 check
  $0 check -r farion1231/cc-switch --tag-prefix ""
  if $0 check -q; then echo "已是最新"; fi

  # 列出最近版本
  $0 list
  $0 list -r edison7009/EchoBird --limit 20

  # 列出指定 release 的所有资产
  $0 list-assets
  $0 list-assets -v 1.2.3 -r edison7009/EchoBird --tag-prefix "v"

  # 列出指定 release 的 .deb 资产（标记架构匹配）
  $0 list-deb
  $0 list-deb -r 2dust/v2rayN --tag-prefix "" --arch arm64

  # 查看信息
  $0 info
  $0 info -r farion1231/cc-switch --tag-prefix ""

  # 卸载
  $0 uninstall
  $0 uninstall -p cc-switch

  # 预演安装（不实际执行）
  $0 install --dry-run -v 1.2.3
  $0 install --dry-run -r edison7009/EchoBird --tag-prefix "v"

  # 使用代理
  $0 --proxy http://127.0.0.1:2080 install
  $0 check --proxy http://127.0.0.1:2080

  # 强制重装并保留缓存
  $0 install -f --keep-cache

  # 校验 sha256 + 断点续传
  $0 install --verify-checksum --resume

  # 指定配置文件 + 自动确认 + 静默
  $0 --config ~/.update-deb.conf install -y -q

  # 覆盖架构检测
  $0 install --arch arm64

  # 手动指定包名
  $0 install -p my-custom-package

  # 组合：指定仓库 + 版本 + 代理 + 预演 + 校验
  $0 install -r edison7009/EchoBird --tag-prefix "v" -v 1.2.3 \\
      --proxy http://127.0.0.1:2080 --dry-run --verify-checksum

  # 组合：检查 + 静默 + 代理（适合 cron）
  $0 check -q --proxy http://127.0.0.1:2080 && echo "up-to-date" || echo "update available"

  # 组合：列表 + 限制条数 + 无颜色（适合管道）
  $0 list --limit 5 --no-color | grep -i pre
EOF
    exit 0
}

# ======================== 参数解析 ========================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            install|uninstall|check|list|info|list-assets|list-deb)
                SUBCOMMAND="$1"; shift ;;
            -r|--repo)
                # 支持逗号分隔（a/b,c/d）和多次 -r 累加
                # 首次 -r 清空配置文件的 REPOS（命令行覆盖配置）
                if [[ -z "${_CLI_REPO_SEEN:-}" ]]; then
                    REPOS=()
                    _CLI_REPO_SEEN=1
                fi
                IFS=',' read -ra _parts <<< "$2"
                REPOS+=("${_parts[@]}")
                REPO="${_parts[0]}"   # 兼容单仓库显示
                shift 2 ;;
            -v|--version)     TARGET_VERSION="$2"; shift 2 ;;
            -f|--force)       FORCE=1; shift ;;
            -p|--package)     MANUAL_PACKAGE="$2"; shift 2 ;;
            --tag-prefix)     TAG_PREFIX="$2"; shift 2 ;;
            --arch)           ARCH_OVERRIDE="$2"; shift 2 ;;
            --limit)          LIST_LIMIT="$2"; shift 2 ;;
            --dry-run)        DRY_RUN=1; shift ;;
            -y|--yes)         ASSUME_YES=1; shift ;;
            --timeout)        TIMEOUT="$2"; shift 2 ;;
            --proxy)          PROXY="$2"; shift 2 ;;
            --cache-dir)      CACHE_DIR="$2"; shift 2 ;;
            --keep-cache)     KEEP_CACHE=1; shift ;;
            --verify-checksum) VERIFY_CHECKSUM=1; shift ;;
            --resume)         RESUME=1; shift ;;
            --no-color)       NO_COLOR=1; shift ;;
            -q|--quiet)       QUIET=1; shift ;;
            -V|--verbose)     VERBOSE=1; shift ;;
            --config)         CONFIG_FILE="$2"; shift 2 ;;
            -h|--help)        usage ;;
            --)               shift; break ;;
            *)                die "未知参数: $1（使用 -h 查看帮助）" ;;
        esac
    done

    # 仓库校验：优先 REPOS 数组，回退 REPO
    if [[ ${#REPOS[@]} -eq 0 && -z "$REPO" ]]; then
        die "未指定仓库（用 -r/--repo 或配置文件设置 REPOS/REPO）"
    fi
    # 若命令行未给 -r，则用 REPO 构造单元素列表
    if [[ ${#REPOS[@]} -eq 0 ]]; then
        REPOS=("$REPO")
    fi
    # 校验每个仓库格式
    for r in "${REPOS[@]}"; do
        if [[ ! "$r" =~ ^[^/]+/[^/]+$ ]]; then
            die "仓库格式错误: ${r}（应为 owner/repo）"
        fi
    done
}

# ======================== 主程序 ========================

main() {
    apply_color_policy
    # 先解析 --config（可能出现在任意位置），再加载配置，最后解析全部参数（命令行覆盖配置）
    local cfg=""
    local args=("$@")
    for ((i=0; i<${#args[@]}; i++)); do
        if [[ "${args[i]}" == "--config" && $((i+1)) -lt ${#args[@]} ]]; then
            cfg="${args[$((i+1))]}"
            break
        fi
    done
    [[ -n "$cfg" ]] && CONFIG_FILE="$cfg"
    load_config
    apply_color_policy
    parse_args "$@"
    apply_proxy

    ARCH=$(detect_arch)

    log_debug "子命令: $SUBCOMMAND | REPO=$REPO | ARCH=$ARCH | TAG_PREFIX=$TAG_PREFIX"
    log_debug "DRY_RUN=$DRY_RUN ASSUME_YES=$ASSUME_YES VERIFY_CHECKSUM=$VERIFY_CHECKSUM RESUME=$RESUME"

    case "$SUBCOMMAND" in
        install)      cmd_install ;;
        uninstall)    cmd_uninstall ;;
        check)        cmd_check ;;
        list)         cmd_list ;;
        list-assets)  cmd_list_assets ;;
        list-deb)     cmd_list_deb ;;
        info)         cmd_info ;;
        *)            die "未知子命令: $SUBCOMMAND" ;;
    esac
}

main "$@"
