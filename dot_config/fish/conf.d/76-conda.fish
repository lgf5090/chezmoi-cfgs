if set -q ANACONDA_HOME; and test -x "$ANACONDA_HOME/bin/conda"
    set -g __FISH_CONDA_EXE "$ANACONDA_HOME/bin/conda"
else if command -q conda
    set -g __FISH_CONDA_EXE (command -s conda)
end

if set -q __FISH_CONDA_EXE; and test -x "$__FISH_CONDA_EXE"
    function _fconda_load
        functions -e conda mamba _fconda_load 2>/dev/null

        set -l conda_setup ("$__FISH_CONDA_EXE" shell.fish hook 2>/dev/null)
        if test -n "$conda_setup"
            string join \n -- $conda_setup | source
        else if set -q ANACONDA_HOME; and test -r "$ANACONDA_HOME/etc/fish/conf.d/conda.fish"
            source "$ANACONDA_HOME/etc/fish/conf.d/conda.fish"
        else
            _fpath_prepend (dirname "$__FISH_CONDA_EXE")
        end
    end

    function conda
        _fconda_load
        conda $argv
    end

    if command -q mamba
        function mamba
            _fconda_load
            mamba $argv
        end
    end
end

if command -q micromamba
    set -g __FISH_MICROMAMBA_EXE (command -s micromamba)

    function micromamba
        functions -e micromamba 2>/dev/null

        set -l micromamba_setup ("$__FISH_MICROMAMBA_EXE" shell hook --shell fish 2>/dev/null)
        test -n "$micromamba_setup"; and string join \n -- $micromamba_setup | source
        micromamba $argv
    end
end
