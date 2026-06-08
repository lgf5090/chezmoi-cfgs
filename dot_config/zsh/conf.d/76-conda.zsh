if [[ -n ${ANACONDA_HOME:-} && -r $ANACONDA_HOME/etc/profile.d/conda.sh ]]; then
  __ZSH_CONDA_EXE=$ANACONDA_HOME/bin/conda
elif (( $+commands[conda] )); then
  __ZSH_CONDA_EXE=${commands[conda]}
fi

if [[ -n ${__ZSH_CONDA_EXE:-} && -x $__ZSH_CONDA_EXE ]]; then
  _zconda_load() {
    local __zsh_conda_setup
    unfunction conda mamba _zconda_load 2>/dev/null

    __zsh_conda_setup=$("$__ZSH_CONDA_EXE" shell.zsh hook 2>/dev/null || :)
    if [[ -n $__zsh_conda_setup ]]; then
      eval "$__zsh_conda_setup"
    elif [[ -n ${ANACONDA_HOME:-} && -r $ANACONDA_HOME/etc/profile.d/conda.sh ]]; then
      source "$ANACONDA_HOME/etc/profile.d/conda.sh"
    else
      _zpath_prepend "${__ZSH_CONDA_EXE:h}"
    fi
  }

  conda() {
    _zconda_load
    conda "$@"
  }

  if (( $+commands[mamba] )); then
    mamba() {
      _zconda_load
      mamba "$@"
    }
  fi
fi

if (( $+commands[micromamba] )); then
  __ZSH_MICROMAMBA_EXE=${commands[micromamba]}

  micromamba() {
    local __zsh_micromamba_setup
    unfunction micromamba 2>/dev/null

    __zsh_micromamba_setup=$("$__ZSH_MICROMAMBA_EXE" shell hook --shell zsh 2>/dev/null || :)
    [[ -n $__zsh_micromamba_setup ]] && eval "$__zsh_micromamba_setup"
    micromamba "$@"
  }
fi
