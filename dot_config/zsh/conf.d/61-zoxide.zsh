if (( $+commands[zoxide] )) && [[ -o interactive ]]; then
  eval "$(zoxide init zsh)"
fi
