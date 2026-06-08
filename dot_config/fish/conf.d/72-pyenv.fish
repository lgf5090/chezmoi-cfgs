set -q PYENV_ROOT; and _fpath_prepend "$PYENV_ROOT/bin"

if command -q pyenv
    pyenv init - fish 2>/dev/null | source
    pyenv virtualenv-init - fish 2>/dev/null | source
end
