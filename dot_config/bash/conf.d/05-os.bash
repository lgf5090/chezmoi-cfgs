case "$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')" in
  linux*) SHELLS_OS=linux ;;
  darwin*) SHELLS_OS=macos ;;
  freebsd*) SHELLS_OS=freebsd ;;
  cygwin*) SHELLS_OS=cygwin ;;
  msys*|mingw*) SHELLS_OS=windows ;;
  *) SHELLS_OS=unknown ;;
esac

if [[ $SHELLS_OS == linux && -r /proc/version ]] \
  && grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
  SHELLS_OS=wsl
fi

export SHELLS_OS
