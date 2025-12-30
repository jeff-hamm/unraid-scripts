# console coloring for kool kids
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# if this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# impersonate a user
alias user="su -ls /bin/bash"

# preserve 'mc' CWD upon F10 exit
alias mc='fn(){ local f=$(mktemp);$(which mc) -P $f "$@";[[ -s $f ]] && cd $(cat $f);rm $f;};fn'

alias v="ls -lA"
