autoload -Uz compinit

_zcompdump="$XDG_CACHE_HOME/zsh/zcompdump-${ZSH_VERSION}"
if [[ ! -s $_zcompdump || $_zcompdump -ot "$ZSH_CONFIG_DIR/config.zsh" ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump

LISTMAX=999999
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
