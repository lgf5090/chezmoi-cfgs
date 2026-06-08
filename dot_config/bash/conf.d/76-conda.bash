if [[ -n ${ANACONDA_HOME:-} && -r $ANACONDA_HOME/etc/profile.d/conda.sh ]]; then
  __BASH_CONDA_EXE=$ANACONDA_HOME/bin/conda
elif command -v conda >/dev/null 2>&1; then
  __BASH_CONDA_EXE=$(command -v conda)
fi

if [[ -n ${__BASH_CONDA_EXE:-} && -x $__BASH_CONDA_EXE ]]; then
  _bconda_load() {
    local __bash_conda_setup
    unset -f conda mamba _bconda_load 2>/dev/null

    __bash_conda_setup=$("$__BASH_CONDA_EXE" shell.bash hook 2>/dev/null || :)
    if [[ -n $__bash_conda_setup ]]; then
      eval "$__bash_conda_setup"
    elif [[ -n ${ANACONDA_HOME:-} && -r $ANACONDA_HOME/etc/profile.d/conda.sh ]]; then
      source "$ANACONDA_HOME/etc/profile.d/conda.sh"
    else
      _bpath_prepend "${__BASH_CONDA_EXE%/*}"
    fi
  }

  conda() {
    _bconda_load
    conda "$@"
  }

  if command -v mamba >/dev/null 2>&1; then
    mamba() {
      _bconda_load
      mamba "$@"
    }
  fi
fi

if command -v micromamba >/dev/null 2>&1; then
  __BASH_MICROMAMBA_EXE=$(command -v micromamba)

  micromamba() {
    local __bash_micromamba_setup
    unset -f micromamba 2>/dev/null

    __bash_micromamba_setup=$("$__BASH_MICROMAMBA_EXE" shell hook --shell bash 2>/dev/null || :)
    [[ -n $__bash_micromamba_setup ]] && eval "$__bash_micromamba_setup"
    micromamba "$@"
  }
fi
