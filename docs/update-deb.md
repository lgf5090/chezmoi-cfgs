# update-deb.sh

`update-deb.sh` updates local Debian packages from `.deb` assets published on GitHub Releases. It is intended for apps that do not have an apt repository but publish installable `.deb` files in each release.

Default target:

```bash
~/.config/common/scripts/shell/update-deb.sh
```

Default configuration file:

```bash
~/.config/common/config/update-deb.conf
```

In this chezmoi repository the source files are:

```bash
dot_config/common/scripts/shell/update-deb.sh
dot_config/common/config/update-deb.conf
```

## What It Does

The script:

1. Reads the configuration file, then applies command-line overrides.
2. Queries GitHub Releases for the latest release, or a specified tag/version.
3. Selects a `.deb` release asset matching the local architecture.
4. Compares the installed Debian package version with the target version.
5. Downloads the selected asset into the cache directory.
6. Copies the `.deb` to a temporary `/tmp/update-deb.XXXXXX/` directory for apt installation.
7. Installs with `apt-get install ./package.deb` by default, so dependencies are handled by apt.

The `/tmp` staging step avoids apt's `_apt` sandbox warning when the cached file is under `~/.cache`.

## Requirements

Required commands:

```bash
dpkg
dpkg-query
dpkg-deb
curl or wget
jq or python3
sudo, unless running as root
apt-get, when using the default apt install method
```

Optional download accelerators:

```bash
aria2c
axel
```

If `aria2c` or `axel` is available, it is used for downloads before falling back to `curl` or `wget`.

## Basic Usage

Update the default repository from the config file:

```bash
update-deb.sh
```

Update a specific repository to its latest release:

```bash
update-deb.sh -r edison7009/EchoBird --tag-prefix v
```

Show what would happen without downloading or installing:

```bash
update-deb.sh -r edison7009/EchoBird --tag-prefix v --dry-run
```

List available `.deb` assets for the target release:

```bash
update-deb.sh -r edison7009/EchoBird --tag-prefix v --list-assets
```

Force the update flow even when the installed version matches the release version:

```bash
update-deb.sh -r edison7009/EchoBird --tag-prefix v --force
```

Answer downgrade/reinstall prompts automatically:

```bash
update-deb.sh -r edison7009/EchoBird --tag-prefix v --yes
```

## Repository Selection

Use one repository:

```bash
update-deb.sh --repo owner/project
```

`-r` and `--repo` are equivalent:

```bash
update-deb.sh -r owner/project
```

Use multiple repositories by repeating `-r`:

```bash
update-deb.sh \
  -r esengine/DeepSeek-Reasonix \
  -r edison7009/EchoBird
```

Use multiple repositories with a comma-separated list:

```bash
update-deb.sh -r esengine/DeepSeek-Reasonix,edison7009/EchoBird
```

Multi-repository mode only updates each repository to its latest release. It cannot be combined with `--version` or `--tag`:

```bash
# Invalid
update-deb.sh -r owner/app1 -r owner/app2 --version 1.2.3
```

When multiple repositories are used, the script continues after a repository fails and exits non-zero at the end if any repository failed.

## Version And Tag Selection

Install the latest release:

```bash
update-deb.sh -r owner/project
```

Install a version and let the script try common tag forms:

```bash
update-deb.sh -r owner/project --version 1.2.3
```

For `--version 1.2.3`, the script tries:

```text
${TAG_PREFIX}1.2.3
v1.2.3
1.2.3
release-1.2.3
rel-1.2.3
version-1.2.3
```

Install an exact release tag:

```bash
update-deb.sh -r owner/project --tag v1.2.3
```

Set the preferred tag prefix:

```bash
update-deb.sh -r edison7009/EchoBird --tag-prefix v
```

The default repository uses:

```bash
TAG_PREFIX="desktop-v"
```

So a release tag like `desktop-v1.11.1` is interpreted as version `1.11.1`.

Include prereleases when selecting the latest release:

```bash
update-deb.sh -r owner/project --include-prerelease
```

Without `--include-prerelease`, GitHub's `/releases/latest` endpoint is used, which ignores prereleases.

## Asset Selection

By default the script selects `.deb` assets matching the local architecture.

Architecture aliases include:

```text
amd64: amd64, x86_64, x64
arm64: arm64, aarch64, arm64v8
armhf: armhf, armv7l, armv7
i386:  i386, i686, x86
```

Override the detected architecture:

```bash
update-deb.sh -r owner/project --arch arm64
```

List assets before deciding:

```bash
update-deb.sh -r owner/project --list-assets
```

Select an exact asset filename:

```bash
update-deb.sh -r owner/project --asset-name 'Project_1.2.3_Linux_x64.deb'
```

Select an asset by regular expression:

```bash
update-deb.sh -r owner/project --asset-regex 'Linux_x64.*\.deb$'
```

Selection priority:

1. `--asset-name`
2. `--asset-regex`
3. Architecture match
4. `all` architecture asset

## Package Name Detection

The script tries to infer the installed Debian package name from the repository name.

Example:

```bash
edison7009/EchoBird -> echo-bird
```

If auto-detection is wrong, specify the package name:

```bash
update-deb.sh -r owner/project --package actual-package-name
```

In the config file:

```bash
PACKAGE_NAME="actual-package-name"
```

For multi-repository mode, a single `PACKAGE_NAME` override applies to every repository, so it is usually better to leave it empty unless all selected repositories intentionally map to the same package name.

## Download, Cache, And Install

Default cache directory:

```bash
${XDG_CACHE_HOME:-$HOME/.cache}/update-deb
```

Download but do not install:

```bash
update-deb.sh -r owner/project --download-only
```

Download to a specific output directory:

```bash
update-deb.sh -r owner/project --download-only --output-dir /tmp
```

Ignore existing cached files and download again:

```bash
update-deb.sh -r owner/project --no-cache
```

Clean the cache directory:

```bash
update-deb.sh --clean-cache
```

Keep temporary files for debugging:

```bash
update-deb.sh -r owner/project --keep-temp
```

Default install method:

```bash
INSTALL_METHOD="apt"
```

This runs:

```bash
sudo apt-get install -y /tmp/update-deb.XXXXXX/package.deb
```

Use `dpkg` mode:

```bash
update-deb.sh -r owner/project --install-method dpkg
```

`dpkg` mode runs `dpkg -i` first and falls back to `apt-get install -f -y` if dependencies are missing.

## Configuration File

Default path:

```bash
~/.config/common/config/update-deb.conf
```

The file is Bash code and is sourced by the script. Use valid Bash assignments.

Minimal config:

```bash
REPO="esengine/DeepSeek-Reasonix"
TAG_PREFIX="desktop-v"
INSTALL_METHOD="apt"
```

Multi-repository config:

```bash
REPOS=(
  "esengine/DeepSeek-Reasonix"
  "edison7009/EchoBird"
)
```

When `REPOS` contains more than one repository, leave these empty:

```bash
TARGET_VERSION=""
TARGET_TAG=""
```

Asset-specific config:

```bash
REPO="owner/project"
TAG_PREFIX="v"
PACKAGE_NAME="project"
ASSET_REGEX="Linux_x64.*\\.deb$"
```

Use a different config file for one run:

```bash
update-deb.sh --config /path/to/update-deb.conf
```

Command-line `-r/--repo` overrides repositories from the config file.

## Complete Config Template

The repository includes a full template at:

```bash
dot_config/common/config/update-deb.conf
```

After applying chezmoi:

```bash
~/.config/common/config/update-deb.conf
```

Important variables:

```bash
REPO="owner/project"
REPOS=()
TAG_PREFIX="v"
TARGET_VERSION=""
TARGET_TAG=""
PACKAGE_NAME=""
ASSET_NAME=""
ASSET_REGEX=""
ARCH=""
INSTALL_METHOD="apt"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/update-deb"
OUTPUT_DIR=""
FORCE=0
ASSUME_YES=0
DRY_RUN=0
LIST_ASSETS=0
DOWNLOAD_ONLY=0
NO_CACHE=0
INCLUDE_PRERELEASE=0
KEEP_TEMP=0
CLEAN_CACHE=0
```

Use `0` for false and `1` for true.

## GitHub API Token

GitHub rate limits unauthenticated API requests. Set either environment variable to authenticate requests:

```bash
export GITHUB_TOKEN="..."
```

or:

```bash
export GH_TOKEN="..."
```

The script sends the token as a GitHub API bearer token.

## Common Examples

Update Reasonix using defaults:

```bash
update-deb.sh
```

Update EchoBird:

```bash
update-deb.sh -r edison7009/EchoBird --tag-prefix v
```

Preview multiple latest updates:

```bash
update-deb.sh \
  -r esengine/DeepSeek-Reasonix \
  -r edison7009/EchoBird \
  --dry-run
```

List assets for a specific tag:

```bash
update-deb.sh -r owner/project --tag v1.2.3 --list-assets
```

Install a specific version:

```bash
update-deb.sh -r owner/project --tag-prefix v --version 1.2.3
```

Download a package to `/tmp` without installing:

```bash
update-deb.sh -r owner/project --download-only --output-dir /tmp
```

Force reinstall/update flow:

```bash
update-deb.sh -r owner/project --force
```

Use a regex when the release publishes several `.deb` variants:

```bash
update-deb.sh -r owner/project --asset-regex 'amd64.*\.deb$'
```

## Notes And Caveats

`apt` may print:

```text
注意，选中 'package' 而非 '/tmp/update-deb.xxxxxx/package.deb'
```

This is normal. It means apt recognized the local `.deb` file as the package named `package`.

Older versions of the script installed directly from `~/.cache/update-deb`, which could cause:

```text
N: 由于文件 '...' 无法被用户 '_apt' 访问，已脱离沙盒...
```

The current script copies the `.deb` to `/tmp/update-deb.XXXXXX/` before apt installation to avoid that warning.

`--force` forces the script to continue past the initial version check. Apt may still decide that an already installed identical package does not need changes.

`--asset-regex` uses regular expression syntax understood by `jq` or Python's `re` fallback. Escape backslashes in config files:

```bash
ASSET_REGEX="amd64.*\\.deb$"
```

Do not loosen permissions on your home directory just to make apt read cached files. The `/tmp` staging behavior is safer.

## Troubleshooting

Check what the script would do:

```bash
update-deb.sh -r owner/project --dry-run
```

List release assets:

```bash
update-deb.sh -r owner/project --list-assets
```

Bypass a wrong architecture match:

```bash
update-deb.sh -r owner/project --asset-name 'exact-file.deb'
```

Bypass a wrong package-name guess:

```bash
update-deb.sh -r owner/project --package actual-package-name
```

Re-download a corrupted cache entry:

```bash
update-deb.sh -r owner/project --no-cache
```

Clean all cached `.deb` files:

```bash
update-deb.sh --clean-cache
```

Keep temporary install files:

```bash
update-deb.sh -r owner/project --keep-temp
```

Run the offline dry-run test script from this development session:

```bash
/tmp/test-update-deb-dry-run.sh
```
