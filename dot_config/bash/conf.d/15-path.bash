_bpath_append \
  "$HOME/.lmstudio/bin" \
  "$HOME/.local/bin" \
  "$HOME/bin" \
  "$HOME/Applications" \
  "$HOME/.local/Applications"

_bpath_prepend \
  "${CARGO_HOME:-$HOME/.cargo}/bin" \
  "$HOME/.rd/bin" \
  "$HOME/.opencode/bin"

[[ -r $HOME/.cargo/env ]] && source "$HOME/.cargo/env"

_bpath_prepend \
  "${BUN_INSTALL:+$BUN_INSTALL/bin}" \
  "${DENO_INSTALL:+$DENO_INSTALL/bin}" \
  "${NPM_CONFIG_PREFIX:+$NPM_CONFIG_PREFIX/bin}" \
  "${PNPM_HOME:+$PNPM_HOME}" \
  "$HOME/.yarn/bin" \
  "$HOME/.config/yarn/global/node_modules/.bin" \
  "$HOME/.volta/bin" \
  "${FNM_DIR:+$FNM_DIR}" \
  "$HOME/.local/share/npm/bin"

_bpath_prepend \
  "${PYENV_ROOT:+$PYENV_ROOT/bin}" \
  "${ANACONDA_HOME:+$ANACONDA_HOME/bin}" \
  "${POETRY_HOME:+$POETRY_HOME/bin}" \
  "$HOME/.poetry/bin" \
  "$HOME/.local/pipx/bin"

_bpath_prepend \
  "${GOPATH:+$GOPATH/bin}" \
  "${GOROOT:+$GOROOT/bin}"

case ${SHELLS_OS:-unknown} in
  linux|wsl)
    _bpath_append \
      /snap/bin \
      /var/lib/snapd/snap/bin \
      /var/lib/flatpak/exports/bin \
      "$HOME/.local/share/flatpak/exports/bin" \
      /opt/bin
    ;;
esac

case ${SHELLS_OS:-unknown} in
  wsl)
    _bpath_append \
      "/mnt/c/Program Files/Microsoft VS Code/bin" \
      "/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
    ;;
  cygwin)
    _bpath_prepend /mingw64/bin
    _bpath_append \
      "/cygdrive/c/Program Files/Microsoft VS Code/bin" \
      "/cygdrive/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
    ;;
  windows)
    _bpath_prepend /mingw64/bin
    _bpath_append \
      "/c/Program Files/Microsoft VS Code/bin" \
      "/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
    ;;
esac

_bpath_prepend \
  "$HOME/.nix-profile/bin" \
  /run/current-system/sw/bin \
  /nix/var/nix/profiles/default/bin

for __bash_brew in \
  /home/linuxbrew/.linuxbrew/bin/brew \
  "$HOME/.linuxbrew/bin/brew" \
  /opt/homebrew/bin/brew \
  /usr/local/bin/brew
do
  if [[ -x $__bash_brew ]]; then
    eval "$("$__bash_brew" shellenv)"
    break
  fi
done
unset __bash_brew

export PATH
