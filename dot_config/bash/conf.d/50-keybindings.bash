case $- in
  *i*)
    bind '"\e[1;5C": forward-word'
    bind '"\e[1;5D": backward-word'
    bind '"\C-a": beginning-of-line'
    bind '"\C-e": end-of-line'
    ;;
esac
