case $- in
  *i*)
    if [[ -r /usr/share/bash-completion/bash_completion ]]; then
      source /usr/share/bash-completion/bash_completion
    elif [[ -r /etc/bash_completion ]]; then
      source /etc/bash_completion
    elif [[ -r /opt/homebrew/etc/profile.d/bash_completion.sh ]]; then
      source /opt/homebrew/etc/profile.d/bash_completion.sh
    elif [[ -r /usr/local/etc/profile.d/bash_completion.sh ]]; then
      source /usr/local/etc/profile.d/bash_completion.sh
    fi
    ;;
esac
