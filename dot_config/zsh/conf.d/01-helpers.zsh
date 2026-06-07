_zpath_prepend() {
  local dir
  for dir in "$@"; do
    [[ -d $dir ]] || continue
    path=("$dir" "${path[@]:#$dir}")
  done
}

_zpath_append() {
  local dir
  for dir in "$@"; do
    [[ -d $dir ]] || continue
    path=("${path[@]:#$dir}" "$dir")
  done
}

_zver_ge() {
  local i n1 n2
  local -a v1=(${(s:.:)1}) v2=(${(s:.:)2})

  for i in 1 2 3; do
    n1=${v1[i]:-0}
    n2=${v2[i]:-0}
    n1=${n1%%[^0-9]*}
    n2=${n2%%[^0-9]*}
    n1=${n1:-0}
    n2=${n2:-0}

    (( n1 > n2 )) && return 0
    (( n1 < n2 )) && return 1
  done

  return 0
}

: "${ZSH_PLUGIN_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins}"
: "${ZSH_PLUGIN_AUTO_INSTALL:=1}"
typeset -gA _ZPLUGIN_LOADED

_zplugin() {
  local owner=$1 repo=$2 entry plugin_dir

  if [[ -z $owner || -z $repo ]]; then
    print -u2 -- "usage: _zplugin <owner> <repo>"
    return 2
  fi

  [[ -n ${_ZPLUGIN_LOADED[$repo]:-} ]] && return 0
  plugin_dir="$ZSH_PLUGIN_DIR/$repo"

  if [[ ! -d $plugin_dir ]]; then
    if [[ $ZSH_PLUGIN_AUTO_INSTALL != 1 ]]; then
      print -u2 -- "zsh: plugin missing, skip $repo"
      return 0
    fi
    if (( ! $+commands[git] )); then
      print -u2 -- "zsh: git not found, skip $repo"
      return 1
    fi
    mkdir -p "$ZSH_PLUGIN_DIR" || return
    git clone --depth=1 "https://github.com/$owner/$repo" "$plugin_dir" \
      || { print -u2 -- "zsh: failed to install $repo"; return 1; }
  fi

  for entry in "$plugin_dir/$repo.plugin.zsh" "$plugin_dir/$repo.zsh" "$plugin_dir"/*.plugin.zsh(N-.); do
    [[ -r $entry ]] || continue
    source "$entry"
    _ZPLUGIN_LOADED[$repo]=1
    return 0
  done

  print -u2 -- "zsh: no plugin entry found for $repo"
  return 1
}

zplugin-update() {
  local dir

  (( $+commands[git] )) || { print -u2 -- "zsh: git not found"; return 1; }
  for dir in "$ZSH_PLUGIN_DIR"/*(/N); do
    [[ -d "$dir/.git" ]] || continue
    print -r -- "Updating ${dir:t}..."
    git -C "$dir" pull --ff-only
  done
}
