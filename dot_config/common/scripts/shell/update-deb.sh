#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

# GitHub release .deb updater.
# Defaults still target DeepSeek Reasonix, but the script is reusable for any
# repository that publishes Debian packages as release assets.

SCRIPT_NAME=${0##*/}
SCRIPT_VERSION="2.0.0"

DEFAULT_REPO="esengine/DeepSeek-Reasonix"
DEFAULT_TAG_PREFIX="desktop-v"
DEFAULT_INSTALL_METHOD="apt"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/update-deb"
CONFIG_FILE="$HOME/.config/common/config/update-deb.conf"

REPO="$DEFAULT_REPO"
REPOS=()
REPO_ARGS_SEEN=0
TARGET_VERSION=""
TARGET_TAG=""
TAG_PREFIX="$DEFAULT_TAG_PREFIX"
PACKAGE_NAME=""
ASSET_REGEX=""
ASSET_NAME=""
ARCH=""
INSTALL_METHOD="$DEFAULT_INSTALL_METHOD"
OUTPUT_DIR=""
FORCE=0
ASSUME_YES=0
DRY_RUN=0
CLEAN_CACHE=0
LIST_ASSETS=0
DOWNLOAD_ONLY=0
NO_CACHE=0
INCLUDE_PRERELEASE=0
KEEP_TEMP=0

HTTP_CLIENT=""
JSON_PARSER=""
TEMP_FILES=()
TEMP_DIRS=()

if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[0;33m'
    BLUE=$'\033[0;34m'
    DIM=$'\033[2m'
    NC=$'\033[0m'
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    DIM=""
    NC=""
fi

log_info()    { printf '%s[INFO]%s %s\n' "$BLUE" "$NC" "$*" >&2; }
log_success() { printf '%s[OK]%s %s\n' "$GREEN" "$NC" "$*" >&2; }
log_warn()    { printf '%s[WARN]%s %s\n' "$YELLOW" "$NC" "$*" >&2; }
log_error()   { printf '%s[ERROR]%s %s\n' "$RED" "$NC" "$*" >&2; }
die()         { log_error "$*"; exit 1; }

cleanup() {
    if [[ "$KEEP_TEMP" -eq 1 ]]; then
        return 0
    fi

    local file
    for file in "${TEMP_FILES[@]}"; do
        if [[ -n "$file" && -f "$file" ]]; then
            rm -f -- "$file"
        fi
    done

    local dir
    for dir in "${TEMP_DIRS[@]}"; do
        if [[ -n "$dir" && -d "$dir" ]]; then
            rm -rf -- "$dir"
        fi
    done

    return 0
}

trap cleanup EXIT
trap 'die "脚本在第 ${LINENO} 行失败"' ERR

usage() {
    cat <<EOF
用法: ${SCRIPT_NAME} [选项]

更新 GitHub Release 中发布的 .deb 软件包。

常用选项:
  -r, --repo OWNER/REPO       GitHub 仓库，默认: ${DEFAULT_REPO}
                            可重复指定，或用逗号分隔多个仓库
  -v, --version VERSION       指定版本，会尝试 tag-prefix/v/release-/rel- 等 tag
  -t, --tag TAG               直接指定 release tag
  -p, --package NAME          指定本地 Debian 包名
  -f, --force                 即使版本相同也重新安装
  -y, --yes                   非交互确认降级或重装
      --dry-run               只展示将执行的动作，不下载/安装
      --download-only         只下载 .deb，不安装
      --list-assets           列出目标 release 中的 .deb 资产后退出

选择选项:
      --tag-prefix PREFIX     指定版本时优先尝试的 tag 前缀，默认: "${DEFAULT_TAG_PREFIX}"
      --asset-regex REGEX     用正则进一步筛选资产文件名
      --asset-name NAME       精确指定资产文件名
      --arch ARCH             覆盖架构自动检测，例如 amd64/arm64
      --include-prerelease    未指定版本/tag 时允许选择最新 prerelease

安装/缓存:
      --install-method MODE   apt 或 dpkg，默认: ${DEFAULT_INSTALL_METHOD}
  -o, --output-dir DIR        下载输出目录，配合 --download-only 常用
      --no-cache              跳过已有缓存并重新下载
  -c, --clean-cache           清理缓存目录后退出
      --keep-temp             保留本次临时文件

其它:
      --config FILE           配置文件路径，默认: ${CONFIG_FILE}
      --version-info          显示脚本版本
  -h, --help                  显示帮助

配置文件:
  ${CONFIG_FILE}

配置示例:
  REPO="owner/project"
  TAG_PREFIX="v"
  PACKAGE_NAME="project"
  ASSET_REGEX="amd64.*\\.deb$"
  INSTALL_METHOD="apt"

环境变量:
  GITHUB_TOKEN 或 GH_TOKEN 可用于提高 GitHub API 限额。

示例:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} -r edison7009/EchoBird --tag-prefix v
  ${SCRIPT_NAME} -r owner/app1 -r owner/app2
  ${SCRIPT_NAME} -r owner/app1,owner/app2 --dry-run
  ${SCRIPT_NAME} --tag desktop-v1.2.3 --list-assets
  ${SCRIPT_NAME} --asset-regex 'amd64.*\\.deb$' --download-only -o /tmp

注意:
  多仓库模式只能更新到各仓库最新版，不能与 --version 或 --tag 一起使用。
EOF
}

show_version() {
    printf '%s %s\n' "$SCRIPT_NAME" "$SCRIPT_VERSION"
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

require_cmd() {
    has_cmd "$1" || die "缺少必要依赖: $1"
}

mktemp_tracked() {
    local file
    file=$(mktemp)
    TEMP_FILES+=("$file")
    printf '%s\n' "$file"
}

mktemp_dir_tracked() {
    local dir
    dir=$(mktemp -d /tmp/update-deb.XXXXXX)
    TEMP_DIRS+=("$dir")
    printf '%s\n' "$dir"
}

load_config() {
    [[ -f "$CONFIG_FILE" ]] || return 0
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
}

add_repo_arg() {
    local value="$1"
    local part
    local parts=()

    IFS=',' read -r -a parts <<<"$value"
    for part in "${parts[@]}"; do
        part="${part#"${part%%[![:space:]]*}"}"
        part="${part%"${part##*[![:space:]]}"}"
        [[ -n "$part" ]] || die "仓库列表中包含空值: $value"
        REPOS+=("$part")
    done
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--repo)
                [[ -n "${2:-}" ]] || die "参数 $1 缺少值"
                if [[ "$REPO_ARGS_SEEN" -eq 0 ]]; then
                    REPOS=()
                    REPO_ARGS_SEEN=1
                fi
                add_repo_arg "$2"
                shift 2
                ;;
            -v|--version)
                [[ -n "${2:-}" ]] || die "参数 $1 缺少值"
                TARGET_VERSION="$2"
                shift 2
                ;;
            -t|--tag)
                [[ -n "${2:-}" ]] || die "参数 $1 缺少值"
                TARGET_TAG="$2"
                shift 2
                ;;
            -p|--package)
                [[ -n "${2:-}" ]] || die "参数 $1 缺少值"
                PACKAGE_NAME="$2"
                shift 2
                ;;
            --tag-prefix)
                [[ -n "${2:-}" ]] || die "参数 $1 缺少值"
                TAG_PREFIX="$2"
                shift 2
                ;;
            --asset-regex)
                [[ -n "${2:-}" ]] || die "参数 $1 缺少值"
                ASSET_REGEX="$2"
                shift 2
                ;;
            --asset-name)
                [[ -n "${2:-}" ]] || die "参数 $1 缺少值"
                ASSET_NAME="$2"
                shift 2
                ;;
            --arch)
                [[ -n "${2:-}" ]] || die "参数 $1 缺少值"
                ARCH="$2"
                shift 2
                ;;
            --install-method)
                [[ -n "${2:-}" ]] || die "参数 $1 缺少值"
                INSTALL_METHOD="$2"
                shift 2
                ;;
            -o|--output-dir)
                [[ -n "${2:-}" ]] || die "参数 $1 缺少值"
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=1
                shift
                ;;
            -y|--yes)
                ASSUME_YES=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --download-only)
                DOWNLOAD_ONLY=1
                shift
                ;;
            --list-assets)
                LIST_ASSETS=1
                shift
                ;;
            --include-prerelease)
                INCLUDE_PRERELEASE=1
                shift
                ;;
            --no-cache)
                NO_CACHE=1
                shift
                ;;
            -c|--clean-cache)
                CLEAN_CACHE=1
                shift
                ;;
            --keep-temp)
                KEEP_TEMP=1
                shift
                ;;
            --config)
                [[ -n "${2:-}" ]] || die "参数 $1 缺少值"
                CONFIG_FILE="$2"
                shift 2
                ;;
            --version-info)
                show_version
                exit 0
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            *)
                die "未知参数: $1"
                ;;
        esac
    done

    [[ $# -eq 0 ]] || die "未知参数: $*"
}

resolve_repos() {
    if [[ ${#REPOS[@]} -eq 0 ]]; then
        add_repo_arg "$REPO"
    fi
}

validate_options() {
    resolve_repos

    local repo
    for repo in "${REPOS[@]}"; do
        [[ "$repo" =~ ^[^/[:space:]]+/[^/[:space:]]+$ ]] || die "仓库格式错误: $repo，应为 owner/repo"
    done

    if [[ -n "$TARGET_VERSION" && -n "$TARGET_TAG" ]]; then
        die "--version 和 --tag 不能同时使用"
    fi

    if [[ ${#REPOS[@]} -gt 1 && ( -n "$TARGET_VERSION" || -n "$TARGET_TAG" ) ]]; then
        die "多个 --repo 只能更新到各仓库最新版，不能同时使用 --version 或 --tag"
    fi

    case "$INSTALL_METHOD" in
        apt|dpkg) ;;
        *) die "--install-method 仅支持 apt 或 dpkg" ;;
    esac

    if [[ -n "$OUTPUT_DIR" ]]; then
        mkdir -p -- "$OUTPUT_DIR"
    fi
}

init_dependencies() {
    require_cmd dpkg
    require_cmd dpkg-query
    require_cmd dpkg-deb

    if has_cmd curl; then
        HTTP_CLIENT="curl"
    elif has_cmd wget; then
        HTTP_CLIENT="wget"
    else
        die "需要 curl 或 wget"
    fi

    if has_cmd jq; then
        JSON_PARSER="jq"
    elif has_cmd python3; then
        JSON_PARSER="python3"
    else
        die "需要 jq 或 python3 解析 GitHub API 响应"
    fi

    if [[ "$INSTALL_METHOD" == "apt" && "$DOWNLOAD_ONLY" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
        require_cmd apt-get
    fi
}

normalize_arch() {
    local arch="$1"
    case "$arch" in
        x86_64|x64) echo "amd64" ;;
        aarch64|arm64v8) echo "arm64" ;;
        armv7l|armv7) echo "armhf" ;;
        i686|x86) echo "i386" ;;
        *) echo "$arch" ;;
    esac
}

detect_arch() {
    if [[ -n "$ARCH" ]]; then
        normalize_arch "$ARCH"
    else
        normalize_arch "$(dpkg --print-architecture 2>/dev/null || uname -m)"
    fi
}

arch_regex() {
    local arch="$1"
    case "$arch" in
        amd64) echo '(^|[^[:alnum:]])(amd64|x86_64|x64)([^[:alnum:]]|$)' ;;
        arm64) echo '(^|[^[:alnum:]])(arm64|aarch64|arm64v8)([^[:alnum:]]|$)' ;;
        armhf) echo '(^|[^[:alnum:]])(armhf|armv7l|armv7)([^[:alnum:]]|$)' ;;
        i386)  echo '(^|[^[:alnum:]])(i386|i686|x86)([^[:alnum:]]|$)' ;;
        all)   echo '(^|[^[:alnum:]])all([^[:alnum:]]|$)' ;;
        *)     printf '(^|[^[:alnum:]])%s([^[:alnum:]]|$)\n' "$arch" ;;
    esac
}

github_header_args_curl() {
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    printf '%s\0%s\0' -H 'Accept: application/vnd.github+json'
    printf '%s\0%s\0' -H 'X-GitHub-Api-Version: 2022-11-28'
    [[ -n "$token" ]] && printf '%s\0%s\0' -H "Authorization: Bearer $token"
}

github_header_args_wget() {
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    printf '%s\0' '--header=Accept: application/vnd.github+json'
    printf '%s\0' '--header=X-GitHub-Api-Version: 2022-11-28'
    [[ -n "$token" ]] && printf '%s\0' "--header=Authorization: Bearer $token"
}

http_get() {
    local url="$1"
    local output="$2"
    local status_file
    status_file=$(mktemp_tracked)

    if [[ "$HTTP_CLIENT" == "curl" ]]; then
        local headers=()
        while IFS= read -r -d '' item; do
            headers+=("$item")
        done < <(github_header_args_curl)

        local status
        status=$(curl -fsSL --connect-timeout 10 --max-time 60 --retry 2 --retry-delay 1 \
            "${headers[@]}" -o "$output" -w '%{http_code}' "$url" 2>"$status_file") || {
            local curl_error
            curl_error=$(<"$status_file")
            log_warn "请求失败: ${url}"
            [[ -n "$curl_error" ]] && log_warn "$curl_error"
            return 1
        }

        [[ "$status" =~ ^2[0-9][0-9]$ ]] || {
            log_warn "请求失败: ${url} (HTTP ${status})"
            return 1
        }
    else
        local headers=()
        while IFS= read -r -d '' item; do
            headers+=("$item")
        done < <(github_header_args_wget)

        wget -q --timeout=60 --tries=3 "${headers[@]}" -O "$output" "$url" 2>"$status_file" || {
            local wget_error
            wget_error=$(<"$status_file")
            log_warn "请求失败: ${url}"
            [[ -n "$wget_error" ]] && log_warn "$wget_error"
            return 1
        }
    fi
}

json_get() {
    local file="$1"
    local expr="$2"

    if [[ "$JSON_PARSER" == "jq" ]]; then
        jq -r "$expr" "$file"
    else
        python3 - "$file" "$expr" <<'PY'
import json
import sys

path, expr = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as fh:
    data = json.load(fh)

if expr == ".tag_name // empty":
    print(data.get("tag_name", "") or "")
elif expr == ".message // empty":
    print(data.get("message", "") or "")
else:
    raise SystemExit(f"unsupported python json expression: {expr}")
PY
    fi
}

json_validate_release() {
    local file="$1"
    local message
    message=$(json_get "$file" '.message // empty' 2>/dev/null || true)
    [[ "$message" == "Not Found" ]] && return 1
    [[ -s "$file" ]] || return 1
}

api_release_url() {
    local tag="$1"
    if [[ -n "$tag" ]]; then
        printf 'https://api.github.com/repos/%s/releases/tags/%s\n' "$REPO" "$tag"
    else
        printf 'https://api.github.com/repos/%s/releases/latest\n' "$REPO"
    fi
}

fetch_release_by_tag() {
    local tag="$1"
    local output="$2"
    local url
    url=$(api_release_url "$tag")

    http_get "$url" "$output" && json_validate_release "$output"
}

fetch_latest_release() {
    local output="$1"

    if [[ "$INCLUDE_PRERELEASE" -eq 0 ]]; then
        fetch_release_by_tag "" "$output"
        return
    fi

    local releases_file
    releases_file=$(mktemp_tracked)
    http_get "https://api.github.com/repos/${REPO}/releases?per_page=20" "$releases_file" || return 1

    if [[ "$JSON_PARSER" == "jq" ]]; then
        jq 'map(select(.draft == false)) | .[0]' "$releases_file" >"$output"
    else
        python3 - "$releases_file" "$output" <<'PY'
import json
import sys

src, dst = sys.argv[1], sys.argv[2]
with open(src, encoding="utf-8") as fh:
    releases = json.load(fh)

release = next((item for item in releases if not item.get("draft")), None)
if release is None:
    raise SystemExit(1)

with open(dst, "w", encoding="utf-8") as fh:
    json.dump(release, fh)
PY
    fi

    json_validate_release "$output"
}

clean_version_input() {
    local version="$1"
    local prefix
    for prefix in "$TAG_PREFIX" v release- rel- version-; do
        if [[ -n "$prefix" && "$version" == "$prefix"* ]]; then
            version="${version#"$prefix"}"
            break
        fi
    done
    printf '%s\n' "$version"
}

possible_tags() {
    local version="$1"
    {
        [[ -n "$TAG_PREFIX" ]] && printf '%s\n' "${TAG_PREFIX}${version}"
        printf '%s\n' "v${version}" "$version" "release-${version}" "rel-${version}" "version-${version}"
    } | awk '!seen[$0]++'
}

resolve_release() {
    local output="$1"

    if [[ -n "$TARGET_TAG" ]]; then
        log_info "查询 release tag: ${TARGET_TAG}"
        fetch_release_by_tag "$TARGET_TAG" "$output" || die "无法获取 release: ${TARGET_TAG}"
        return
    fi

    if [[ -n "$TARGET_VERSION" ]]; then
        local clean_version tag
        clean_version=$(clean_version_input "$TARGET_VERSION")
        TARGET_VERSION="$clean_version"

        while IFS= read -r tag; do
            log_info "尝试 tag: ${tag}"
            if fetch_release_by_tag "$tag" "$output"; then
                TARGET_TAG="$tag"
                return
            fi
        done < <(possible_tags "$TARGET_VERSION")

        die "未找到版本 ${TARGET_VERSION} 对应的 Release"
    fi

    log_info "查询最新 release"
    fetch_latest_release "$output" || die "无法获取最新 release"
}

release_tag_name() {
    local release_file="$1"
    local tag
    tag=$(json_get "$release_file" '.tag_name // empty')
    [[ -n "$tag" && "$tag" != "null" ]] || die "Release 响应中没有 tag_name"
    printf '%s\n' "$tag"
}

version_from_tag() {
    local tag="$1"
    local version="$tag"
    local prefix

    for prefix in "$TAG_PREFIX" v release- rel- version-; do
        if [[ -n "$prefix" && "$version" == "$prefix"* ]]; then
            version="${version#"$prefix"}"
            break
        fi
    done

    printf '%s\n' "$version"
}

list_deb_assets() {
    local release_file="$1"

    if [[ "$JSON_PARSER" == "jq" ]]; then
        jq -r '.assets[]? | select(.name | test("\\.deb$"; "i")) | "\(.name)\t\(.size // 0)\t\(.browser_download_url)"' "$release_file"
    else
        python3 - "$release_file" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    data = json.load(fh)

for asset in data.get("assets", []):
    name = asset.get("name", "")
    if name.lower().endswith(".deb"):
        print(f"{name}\t{asset.get('size', 0) or 0}\t{asset.get('browser_download_url', '')}")
PY
    fi
}

print_deb_assets() {
    local release_file="$1"
    local found=0

    while IFS=$'\t' read -r name size url; do
        found=1
        printf '%s%s%s  %s bytes\n  %s\n' "$DIM" "$name" "$NC" "$size" "$url"
    done < <(list_deb_assets "$release_file")

    [[ "$found" -eq 1 ]] || log_warn "该 release 中没有 .deb 资产"
}

select_asset() {
    local release_file="$1"
    local arch="$2"
    local arch_pattern
    arch_pattern=$(arch_regex "$arch")

    if [[ "$JSON_PARSER" == "jq" ]]; then
        jq -r \
            --arg asset_name "$ASSET_NAME" \
            --arg asset_regex "$ASSET_REGEX" \
            --arg arch_pattern "$arch_pattern" '
            [
              .assets[]?
              | select(.name | test("\\.deb$"; "i"))
              | {
                  name,
                  url: .browser_download_url,
                  rank: (
                    if ($asset_name != "" and .name == $asset_name) then 400
                    elif ($asset_name != "") then -1
                    elif ($asset_regex != "" and (.name | test($asset_regex; "i"))) then 300
                    elif ($asset_regex != "") then -1
                    elif (.name | test($arch_pattern; "i")) then 200
                    elif (.name | test("(^|[^[:alnum:]])all([^[:alnum:]]|$)"; "i")) then 100
                    else 0
                    end
                  )
                }
              | select(.rank > 0)
            ]
            | sort_by(.rank)
            | reverse
            | .[0]
            | select(. != null)
            | "\(.name)\t\(.url)"' "$release_file"
    else
        python3 - "$release_file" "$ASSET_NAME" "$ASSET_REGEX" "$arch_pattern" <<'PY'
import json
import re
import sys

path, asset_name, asset_regex, arch_pattern = sys.argv[1:5]
with open(path, encoding="utf-8") as fh:
    data = json.load(fh)

asset_re = re.compile(asset_regex, re.I) if asset_regex else None
arch_re = re.compile(arch_pattern, re.I)
all_re = re.compile(r"(^|[^A-Za-z0-9])all([^A-Za-z0-9]|$)", re.I)

candidates = []
for asset in data.get("assets", []):
    name = asset.get("name", "")
    if not name.lower().endswith(".deb"):
        continue
    rank = 0
    if asset_name:
        rank = 400 if name == asset_name else -1
    elif asset_re:
        rank = 300 if asset_re.search(name) else -1
    elif arch_re.search(name):
        rank = 200
    elif all_re.search(name):
        rank = 100

    if rank > 0:
        candidates.append((rank, name, asset.get("browser_download_url", "")))

if candidates:
    candidates.sort(reverse=True)
    _, name, url = candidates[0]
    print(f"{name}\t{url}")
PY
    fi
}

repo_slug() {
    printf '%s\n' "${REPO##*/}"
}

detect_package_name() {
    if [[ -n "$PACKAGE_NAME" ]]; then
        printf '%s\n' "$PACKAGE_NAME"
        return
    fi

    local slug lower_slug exact normalized words candidate pkg pkg_lower word all_found
    slug=$(repo_slug)
    lower_slug=$(printf '%s\n' "$slug" | tr '[:upper:]' '[:lower:]')

    exact=$(dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -i -F "$slug" | head -n 1 || true)
    if [[ -n "$exact" ]]; then
        printf '%s\n' "$exact"
        return
    fi

    normalized=$(printf '%s\n' "$slug" \
        | sed -E 's/[-_]+/ /g; s/([[:lower:]])([[:upper:]])/\1 \2/g' \
        | tr '[:upper:]' '[:lower:]')
    IFS=' ' read -r -a words <<<"$normalized"

    candidate=""
    while IFS= read -r pkg; do
        pkg_lower=$(printf '%s\n' "$pkg" | tr '[:upper:]' '[:lower:]')
        all_found=1
        for word in "${words[@]:-}"; do
            [[ -z "$word" ]] && continue
            if [[ "$pkg_lower" != *"$word"* ]]; then
                all_found=0
                break
            fi
        done

        if [[ "$all_found" -eq 1 ]]; then
            candidate="$pkg"
            break
        fi
    done < <(dpkg-query -W -f='${Package}\n' 2>/dev/null || true)

    if [[ -n "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return
    fi

    case "$lower_slug" in
        deepseek-reasonix) printf '%s\n' "reasonix-desktop" ;;
        *) printf '%s\n' "$lower_slug" ;;
    esac
}

installed_version() {
    local package="$1"
    dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true
}

version_compare() {
    local left="$1"
    local right="$2"

    if dpkg --compare-versions "$left" gt "$right"; then
        echo 1
    elif dpkg --compare-versions "$left" lt "$right"; then
        echo -1
    else
        echo 0
    fi
}

confirm() {
    local prompt="$1"

    if [[ "$ASSUME_YES" -eq 1 ]]; then
        log_info "${prompt} yes"
        return 0
    fi

    local answer
    read -r -p "${prompt} [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

download_command() {
    local url="$1"
    local output="$2"

    if has_cmd aria2c; then
        aria2c -x 4 -s 4 -d "$(dirname "$output")" -o "$(basename "$output")" "$url"
    elif has_cmd axel; then
        axel -n 4 -o "$output" "$url"
    elif has_cmd curl; then
        curl -fL --retry 2 --retry-delay 1 --connect-timeout 10 -o "$output" "$url"
    elif has_cmd wget; then
        wget --show-progress -O "$output" "$url"
    else
        die "未找到可用下载工具: aria2c、axel、curl 或 wget"
    fi
}

download_asset() {
    local url="$1"
    local asset_name="$2"
    local output_dir="${OUTPUT_DIR:-$CACHE_DIR}"
    local cache_file="$CACHE_DIR/$asset_name"
    local output_file="$output_dir/$asset_name"

    mkdir -p -- "$CACHE_DIR" "$output_dir"

    if [[ "$NO_CACHE" -eq 0 && -f "$cache_file" ]]; then
        log_info "使用缓存: $cache_file"
    else
        log_info "下载: $asset_name"
        local partial="${cache_file}.part"
        rm -f -- "$partial"
        download_command "$url" "$partial"
        mv -f -- "$partial" "$cache_file"
    fi

    if [[ "$output_file" != "$cache_file" ]]; then
        cp -f -- "$cache_file" "$output_file"
    fi

    printf '%s\n' "$output_file"
}

deb_field() {
    local deb_file="$1"
    local field="$2"
    dpkg-deb -f "$deb_file" "$field" 2>/dev/null || true
}

run_root() {
    if [[ "$EUID" -eq 0 ]]; then
        "$@"
    elif has_cmd sudo; then
        sudo "$@"
    else
        die "需要 root 权限执行: $*，但未找到 sudo"
    fi
}

stage_deb_for_apt() {
    local deb_file="$1"
    local stage_dir staged_file

    stage_dir=$(mktemp_dir_tracked)
    staged_file="$stage_dir/$(basename "$deb_file")"

    cp -f -- "$deb_file" "$staged_file"
    chmod 0644 "$staged_file"

    printf '%s\n' "$staged_file"
}

install_deb() {
    local deb_file="$1"

    log_info "安装: $deb_file"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        if [[ "$INSTALL_METHOD" == "apt" ]]; then
            log_info "dry-run: 会复制到 /tmp 后执行 apt-get install -y $(basename "$deb_file")"
        else
            log_info "dry-run: dpkg -i $deb_file"
        fi
        return
    fi

    if [[ "$INSTALL_METHOD" == "apt" ]]; then
        local staged_deb
        staged_deb=$(stage_deb_for_apt "$deb_file")
        log_info "apt 安装文件: $staged_deb"
        run_root apt-get install -y "$staged_deb"
        return
    fi

    if ! run_root dpkg -i "$deb_file"; then
        log_warn "dpkg 安装失败，尝试使用 apt-get 修复依赖"
        require_cmd apt-get
        run_root apt-get install -f -y
        run_root dpkg --configure -a
    fi
}

clean_cache() {
    if [[ -d "$CACHE_DIR" ]]; then
        log_info "清理缓存目录: $CACHE_DIR"
        rm -rf -- "$CACHE_DIR"
    else
        log_info "缓存目录不存在: $CACHE_DIR"
    fi
    log_success "缓存清理完毕"
}

update_one_repo() {
    REPO="$1"

    local release_file
    release_file=$(mktemp_tracked)

    log_info "仓库: $REPO"
    log_info "系统架构: $ARCH"
    [[ -n "$TAG_PREFIX" ]] && log_info "Tag 前缀: $TAG_PREFIX"

    resolve_release "$release_file"

    local tag target_version
    tag=$(release_tag_name "$release_file")
    target_version=$(version_from_tag "$tag")

    log_info "目标 release: $tag"
    log_info "推断版本: $target_version"

    if [[ "$LIST_ASSETS" -eq 1 ]]; then
        print_deb_assets "$release_file"
        return 0
    fi

    local selected asset_name download_url
    selected=$(select_asset "$release_file" "$ARCH" || true)
    [[ -n "$selected" ]] || {
        log_warn "未找到匹配条件的 .deb 资产"
        print_deb_assets "$release_file"
        die "请使用 --asset-name 或 --asset-regex 指定要安装的资产"
    }

    IFS=$'\t' read -r asset_name download_url <<<"$selected"
    [[ -n "$asset_name" && -n "$download_url" ]] || die "无法解析 release 资产"
    log_info "选择资产: $asset_name"

    local package current cmp
    package=$(detect_package_name)
    current=$(installed_version "$package")

    log_info "目标包名: $package"
    if [[ -n "$current" ]]; then
        log_success "当前版本: $current"
    else
        log_warn "当前未安装: $package"
    fi

    if [[ -n "$current" && "$FORCE" -eq 0 ]]; then
        cmp=$(version_compare "$current" "$target_version")
        if [[ "$cmp" -eq 0 ]]; then
            log_success "已是目标版本: $current"
            return 0
        elif [[ "$cmp" -eq 1 ]]; then
            confirm "当前版本 $current 高于目标版本 $target_version，确认降级安装？" || {
                log_info "已取消"
                return 0
            }
        else
            log_info "发现可更新版本: $current -> $target_version"
        fi
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "dry-run: 将下载 $download_url"
        [[ "$DOWNLOAD_ONLY" -eq 1 ]] || install_deb "$CACHE_DIR/$asset_name"
        return 0
    fi

    local deb_file deb_package deb_version deb_arch
    deb_file=$(download_asset "$download_url" "$asset_name")
    deb_package=$(deb_field "$deb_file" Package)
    deb_version=$(deb_field "$deb_file" Version)
    deb_arch=$(deb_field "$deb_file" Architecture)

    [[ -n "$deb_package" ]] || die "下载文件不是有效的 Debian 包: $deb_file"
    log_info "包元数据: ${deb_package} ${deb_version:-unknown} (${deb_arch:-unknown})"

    if [[ -n "$current" && -n "$deb_version" && "$FORCE" -eq 0 ]]; then
        cmp=$(version_compare "$current" "$deb_version")
        if [[ "$cmp" -eq 0 ]]; then
            log_success "已安装的 Debian 包版本与下载包一致: $current"
            return 0
        elif [[ "$cmp" -eq 1 ]]; then
            confirm "当前版本 $current 高于下载包版本 $deb_version，确认降级安装？" || {
                log_info "已取消"
                return 0
            }
        fi
    fi

    if [[ "$DOWNLOAD_ONLY" -eq 1 ]]; then
        log_success "下载完成: $deb_file"
        return 0
    fi

    install_deb "$deb_file"
    log_success "安装完成"
}

main() {
    # --config needs to be honored before loading defaults from the config file.
    local early_arg
    for ((early_arg = 1; early_arg <= $#; early_arg++)); do
        if [[ "${!early_arg}" == "--config" ]]; then
            local next_index=$((early_arg + 1))
            [[ "$next_index" -le $# ]] || die "参数 --config 缺少值"
            CONFIG_FILE="${!next_index}"
            break
        fi
    done

    load_config
    parse_args "$@"
    validate_options

    if [[ "$CLEAN_CACHE" -eq 1 ]]; then
        clean_cache
        exit 0
    fi

    init_dependencies

    ARCH=$(detect_arch)

    local repo failures=0
    for repo in "${REPOS[@]}"; do
        if [[ ${#REPOS[@]} -gt 1 ]]; then
            log_info "========== $repo =========="
        fi

        if ( update_one_repo "$repo" ); then
            :
        else
            log_error "仓库处理失败: $repo"
            failures=$((failures + 1))
        fi
    done

    if [[ "$failures" -gt 0 ]]; then
        die "${failures}/${#REPOS[@]} 个仓库处理失败"
    fi
}

main "$@"
